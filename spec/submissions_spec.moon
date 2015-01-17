import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"
import encode_query_string from require "lapis.util"

factory = require "spec.factory"
import request, request_as from require "spec.helpers"

import Streaks, Users, Submissions, StreakUsers, StreakSubmissions from require "models"

date = require "date"

describe "submissions", ->
  local current_user

  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Streaks, Users, Submissions, StreakUsers, StreakSubmissions
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
    local streak

    before_each ->
      streak = factory.Streaks state: "during"
      factory.StreakUsers user_id: current_user.id, streak_id: streak.id

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
      assert.same 1, #Submissions\select!
      assert.same 1, #StreakSubmissions\select!

    it "should submit to multiple streaks", ->
      streak2 = factory.Streaks state: "during"
      factory.StreakUsers user_id: current_user.id, streak_id: streak2.id

      status, res = do_submit {
        ["submit_to[#{streak.id}]"]: "yes"
        ["submit_to[#{streak2.id}]"]: "yes"
        "submission[title]": ""
        "submission[user_rating]": "neutral"
      }
      assert.truthy res.success

      assert.same 1, #Submissions\select!
      assert.same 2, #StreakSubmissions\select!

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
