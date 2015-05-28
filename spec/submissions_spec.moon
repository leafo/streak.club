db = require "lapis.db"

import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"
import encode_query_string from require "lapis.util"

factory = require "spec.factory"
import request, request_as from require "spec.helpers"

import Streaks, Users, Submissions, StreakUsers, StreakSubmissions, SubmissionLikes, SubmissionTags from require "models"

date = require "date"

describe "submissions", ->
  local current_user

  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Streaks, Users, Submissions, StreakUsers, StreakSubmissions, SubmissionLikes, SubmissionTags
    current_user = factory.Users!

  it "not render submit page when not part of any streaks", ->
    status, _, headers = request_as current_user, "/submit"
    assert.same 302, status

  it "should render submit page when part of one active streak", ->
    streak = factory.Streaks state: "during"
    factory.StreakUsers user_id: current_user.id, streak_id: streak.id

    status = request_as current_user, "/submit"
    assert.same 200, status

  it "should render submit page when part of multiple streaks", ->
    for i=1,3
      streak = factory.Streaks state: "during"
      factory.StreakUsers user_id: current_user.id, streak_id: streak.id

    status = request_as current_user, "/submit"
    assert.same 200, status

  it "should render submit page when part of multiple streaks and streak selected", ->
    streaks = for i=1,3
      streak = factory.Streaks state: "during"
      factory.StreakUsers user_id: current_user.id, streak_id: streak.id
      streak

    status = request_as current_user, "/submit?streak_id=#{streaks[2].id}"
    assert.same 200, status

  it "should not render submit when there are no available streaks", ->
    for i=1,2
      streak = factory.Streaks state: "during"
      factory.StreakUsers user_id: current_user.id, streak_id: streak.id
      factory.StreakSubmissions streak_id: streak.id, user_id: current_user.id

    status = request_as current_user, "/submit"
    assert.same 302, status

  describe "late submit", ->
    local streak, submit_url, submit_stamp

    before_each ->
      streak = factory.Streaks state: "during"
      factory.StreakUsers user_id: current_user.id, streak_id: streak.id

      submit_stamp = date(true)\adddays(-2)\fmt Streaks.day_format_str

      submit_url = "/submit?" .. encode_query_string {
        expires: os.time! + 60*10
        date: submit_stamp
        streak_id: streak.id
        user_id: current_user.id
      }

    it "should not render submit for date with no signature", ->
      status = request_as current_user, submit_url
      assert.same 404, status

    it "should render submit for date with signature", ->
      import signed_url from require "helpers.url"

      status = request_as current_user, signed_url submit_url
      assert.same 200, status

    it "should not render submit for date with signature if already submitted", ->
      factory.StreakSubmissions {
        user_id: current_user.id
        streak_id: streak.id
        submit_time: submit_stamp
        late_submit: true
      }

      import signed_url from require "helpers.url"

      status = request_as current_user, signed_url submit_url
      assert.same 302, status

    it "should not render submit for other user", ->
      other_user = factory.Users!
      factory.StreakUsers user_id: other_user.id, streak_id: streak.id

      import signed_url from require "helpers.url"
      status = request_as other_user, signed_url submit_url
      assert.same 404, status

    it "should late submit", ->
      import signed_url from require "helpers.url"
      status, res = request_as current_user, signed_url(submit_url), {
        post: {
          ["submit_to[#{streak.id}]"]: "on"
          "submission[title]": "yeah"
          "submission[user_rating]": "neutral"
        }
        expect: "json"
      }

      assert.same 200, status
      assert.truthy res.success
      submissions = Submissions\select!
      assert 1, #submissions

      submits = StreakSubmissions\select!
      assert 1, #submits

      submit = unpack submits
      assert.same {
        streak_id: streak.id
        submission_id: submissions[1].id
        user_id: current_user.id
        submit_time: "#{submit_stamp} 23:59:50"
        late_submit: true
      }, submit

  describe "submitting", ->
    local streak, streak_user

    before_each ->
      streak = factory.Streaks state: "during"
      streak_user = factory.StreakUsers user_id: current_user.id, streak_id: streak.id

    do_submit = (post) ->
      request_as current_user, "/submit", {
        :post
        expect: "json"
      }

    it "should require a streak to submit to", ->
      status, res = do_submit {
        "submission[title]": ""
        "submission[user_rating]": "neutral"
      }

      assert.same {
        errors: { "you must choose a streak to submit to" }
      }, res
      assert.same 0, #Submissions\select!

    it "should not allow submission to unrelated streak", ->
      other_streak = factory.Streaks!

      status, res = do_submit {
        ["submit_to[#{other_streak.id}]"]: "yes"
        "submission[title]": ""
        "submission[user_rating]": "neutral"
      }

      assert.same {
        errors: { "you must choose a streak to submit to" }
      }, res
      assert.same 0, #Submissions\select!

    it "should submit a blank submission", ->
      status, res = do_submit {
        ["submit_to[#{streak.id}]"]: "yes"
        "submission[title]": ""
        "submission[user_rating]": "neutral"
      }
      assert.truthy res.success
      submission = assert unpack(Submissions\select!), "missing submission"

      assert.same nil, submission.title
      assert.same Submissions.user_ratings.neutral, submission.user_rating
      assert.same false, submission.hidden
      assert.same current_user.id, submission.user_id

      assert.same 1, #StreakSubmissions\select!

      streak_user\refresh!
      assert.same 1, streak_user.current_streak
      assert.same 1, streak_user.longest_streak
      assert.truthy streak_user.last_submitted_at

      current_user\refresh!
      assert.same 1, current_user.submissions_count
      assert.same 0, current_user.hidden_submissions_count

    it "should tag submission on submit", ->
      status, res = do_submit {
        ["submit_to[#{streak.id}]"]: "yes"
        "submission[title]": "Hello world"
        "submission[user_rating]": "neutral"
        "submission[tags]": "one,two,three,one"
      }

      assert.same 3, SubmissionTags\count!
      assert.same {"one", "three", "two"},
        [t.slug for t in *SubmissionTags\select "order by slug"]

    it "should submit to multiple streaks", ->
      streak2 = factory.Streaks state: "during"
      streak_user2 = factory.StreakUsers user_id: current_user.id, streak_id: streak2.id

      status, res = do_submit {
        ["submit_to[#{streak.id}]"]: "yes"
        ["submit_to[#{streak2.id}]"]: "yes"
        "submission[title]": ""
        "submission[user_rating]": "neutral"
      }
      assert.truthy res.success

      assert.same 1, #Submissions\select!
      assert.same 2, #StreakSubmissions\select!

      for su in *{streak_user, streak_user2}
        su\refresh!
        assert.same 1, su.current_streak
        assert.same 1, su.longest_streak
        assert.truthy su.last_submitted_at

    it "should mark submission hidden when submitting to hidden streak", ->
      streak2 = factory.Streaks {
        state: "during"
        publish_status: "hidden"
      }

      streak_user2 = factory.StreakUsers user_id: current_user.id, streak_id: streak2.id

      status, res = do_submit {
        ["submit_to[#{streak.id}]"]: "yes"
        ["submit_to[#{streak2.id}]"]: "yes"
        "submission[title]": ""
        "submission[user_rating]": "neutral"
      }

      assert.falsy res.errors
      current_user\refresh!
      assert.same 1, current_user.submissions_count
      assert.same 1, current_user.hidden_submissions_count

      submission = assert unpack Submissions\select!
      assert.truthy submission.hidden

    it "should not allow submission to streak already submitted to", ->
      factory.StreakSubmissions streak_id: streak.id, user_id: current_user.id

      status, res = request_as current_user, "/submit", {
        post: {
          ["submit_to[#{streak.id}]"]: "yes"
          "submission[title]": ""
          "submission[user_rating]": "neutral"
        }
      }

      assert.same 302, status
      assert.same 1, #Submissions\select!

  describe "with submission", ->
    local submission, submission_owner

    before_each ->
      submission = factory.Submissions!
      submission_owner = submission\get_user!

    it "should redirect to correct slug with missing slug", ->
      status, _, headers = request_as nil, "/submission/#{submission.id}"
      assert.same 302, status
      assert.same "http://127.0.0.1/p/#{submission.id}/#{submission\slug!}", headers.location

    it "should redirect to correct slug with invalid slug", ->
      status, _, headers = request_as nil, "/p/#{submission.id}/#{submission\slug!}-fake"
      assert.same 302, status
      assert.same "http://127.0.0.1/p/#{submission.id}/#{submission\slug!}", headers.location

    it "should show submission as anon", ->
      status = request_as nil, "/p/#{submission.id}/#{submission\slug!}"
      assert.same 200, status

    it "should show submission as other user", ->
      status = request_as current_user, "/p/#{submission.id}/#{submission\slug!}"
      assert.same 200, status

    it "should show submission as owner", ->
      status = request_as submission_owner, "/p/#{submission.id}/#{submission\slug!}"
      assert.same 200, status

    it "should show submission when there is no slug", ->
      submission\update title: db.NULL
      status = request_as current_user, "/submission/#{submission.id}"
      assert.same 200, status

    it "should redirect to no slug url when slug provided for titleless submission", ->
      submission\update title: db.NULL
      status, _, headers = request_as nil, "/p/#{submission.id}/blguahgegfefe"
      assert.same 302, status
      assert.same "http://127.0.0.1/submission/#{submission.id}", headers.location


  describe "submission likes", ->
    local submission
    before_each ->
      truncate_tables SubmissionLikes
      submission = factory.Submissions!

    it "should like submission", ->
      status, res = request_as current_user, "/submission/#{submission.id}/like", {
        post: {}
        expect: "json"
      }

      assert.same 200, status
      assert.same {
        success: true
        count: 1
      }, res

      current_user\refresh!
      assert.same 1, current_user.likes_count
      submission\refresh!
      assert.same 1, submission.likes_count

    it "should fail when double liking submission", ->
      SubmissionLikes\create user_id: current_user.id, submission_id: submission.id
      status, res = request_as current_user, "/submission/#{submission.id}/like", {
        post: {}
        expect: "json"
      }

      assert.same 200, status
      assert.same {
        success: false
        count: 1
      }, res

      current_user\refresh!
      assert.same 1, current_user.likes_count

      submission\refresh!
      assert.same 1, submission.likes_count

    it "should unlike submission", ->
      SubmissionLikes\create user_id: current_user.id, submission_id: submission.id

      status, res = request_as current_user, "/submission/#{submission.id}/unlike", {
        post: {}
        expect: "json"
      }

      assert.same 200, status
      assert.same {
        success: true
        count: 0
      }, res


      current_user\refresh!
      assert.same 0, current_user.likes_count

      submission\refresh!
      assert.same 0, submission.likes_count

  it "should get title", ->
    submit = factory.StreakSubmissions!
    submission = submit\get_submission!
    assert.truthy submission\meta_title!
    submission.title = nil
    assert.truthy submission\meta_title!

  it "should delete submission not in streak", ->
    sub = factory.Submissions!
    sub\delete!

  it "should delete submission in streak", ->
    streak_sub = factory.StreakSubmissions!
    streak = streak_sub\get_streak!
    sub = streak_sub\get_submission!

    -- user isn't joined in factory by default
    streak\join streak_sub\get_user!
    streak\recount!

    sub\delete!

    streak\refresh!
    assert.same 0, streak.submissions_count
    assert.same 0, #Submissions\select!
    assert.same 0, #StreakSubmissions\select!

  it "should delete submission in many streaks", ->
    streak_sub = factory.StreakSubmissions!
    sub = streak_sub\get_submission!
    factory.StreakSubmissions submission_id: sub.id, user_id: sub.user_id

    for s in *Streaks\select!
      s\join streak_sub\get_user!
      s\recount!

    sub\delete!

    count = unpack db.query "select sum(submissions_count) from streaks"
    assert.same 0, count.sum

  it "should delete streak submission, (but not submission)", ->
    streak_sub = factory.StreakSubmissions!
    streak = streak_sub\get_streak!

    streak\join streak_sub\get_user!
    streak\recount!

    streak_user = streak_sub\get_streak_user!
    streak_user\update_streaks!

    assert.same 1, streak_user.current_streak
    assert.same 1, streak_user.longest_streak
    assert.truthy streak_user.last_submitted_at

    streak_sub.streak_user = nil -- force it to be refetched
    streak_sub\delete!
    streak_user\refresh!

    assert.same 0, streak_user.current_streak
    assert.same 0, streak_user.longest_streak
    assert.falsy streak_user.last_submitted_at

  describe "streak users", ->
    it "should get correct streak for recent submission", ->
      su = factory.StreakUsers!

      submit = factory.StreakSubmissions {
        user_id: su.user_id
        streak_id: su.streak_id
      }

      su\refresh!
      su\update_streaks!

      assert.same 1, su\get_current_streak!
      assert.same 1, su\get_longest_streak!

    it "should get correct streak for old submission", ->
      streak = factory.Streaks state: "during"
      su = factory.StreakUsers streak_id: streak.id

      submit = factory.StreakSubmissions {
        user_id: su.user_id
        streak_id: streak.id
        submit_time: db.raw "date_trunc('second', now() at time zone 'utc' - '2 days'::interval)"
      }

      su\refresh!
      su\update_streaks!

      assert.same 0, su\get_current_streak!
      assert.same 1, su\get_longest_streak!

    it "should get correct streak when time elapses", ->
      streak = factory.Streaks state: "during"
      su = factory.StreakUsers!

      submit = factory.StreakSubmissions {
        user_id: su.user_id
        streak_id: su.streak_id
      }

      su\refresh!
      su\update_streaks!

      ago = db.raw "date_trunc('second', now() at time zone 'utc' - '2 days'::interval)"
      submit\update submit_time: ago
      su\update last_submitted_at: ago

      assert.same 0, su\get_current_streak!
      assert.same 1, su\get_longest_streak!
