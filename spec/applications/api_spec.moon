import use_test_server from require "lapis.spec"
import request from require "spec.helpers"
import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"

describe "api", ->
  use_test_server!

  import Users, ApiKeys, Streaks, StreakUsers, Submissions,
    StreakSubmissions, Uploads, SubmissionLikes from require "spec.models"

  it "it should create api key", ->
    assert factory.ApiKeys!

  it "it should log in user", ->
    user = factory.Users username: "leafo", password: "leafo"
    status, res = request "/api/1/login", {
      post: {
        source: "ios"
        username: "leafo"
        password: "leafo"
      }
      expect: "json"
    }

    assert.same 200, status, "status status"
    assert.nil res.errors, "expect no errors"
    key = assert res.key, "api key"
    assert.same ApiKeys.sources.ios, key.source
    assert.same user.id, key.user_id

    -- try again, re-use key
    status, res = request "/api/1/login", {
      post: {
        source: "ios"
        username: "leafo"
        password: "leafo"
      }
      expect: "json"
    }

    assert.same key, res.key


  it "should register user", ->
    status, res = request "/api/1/register", {
      post: {
        source: "ios"
        username: "leafo"
        password: "leafo"
        password_repeat: "leafo"
        email: "leafo@example.com"
      }
      expect: "json"
    }

    assert.truthy res.key
    assert.same 1, #Users\select!


  describe "with key", ->
    local api_key, current_user

    request_with_key = (url, opts={}) ->
      opts.get or= {}
      opts.get.key = api_key.key
      opts.expect = "json"
      request url, opts

    before_each ->
      api_key = factory.ApiKeys!
      current_user = api_key\get_user!

    it "should get empty my-streaks", ->
      status, res = request_with_key "/api/1/my-streaks"
      assert.same 200, status
      assert.same {
        hosted: {}
        joined: {}
      }, res

    it "should get my-streaks with joined streaks", ->
      s1 = factory.Streaks state: "before_start"
      s2 = factory.Streaks state: "after_end"
      s3 = factory.Streaks state: "during"

      for s in *{s1, s2}
        factory.StreakUsers user_id: current_user.id, streak_id: s.id

      status, res = request_with_key "/api/1/my-streaks"
      assert.same 200, status

      assert.same {}, res.hosted
      assert.same {s1.id}, [s.id for s in *res.joined.upcoming]
      assert.same {s2.id}, [s.id for s in *res.joined.completed]
      assert.same nil, res.joined.active

    it "should get my-streaks with hosted streaks", ->
      s = factory.Streaks state: "before_start", user_id: current_user.id
      status, res = request_with_key "/api/1/my-streaks"

      import types from require "tableshape"

      t = types.shape {
        hosted: types.table
        joined: types.table
      }

      assert t res

      assert.same {}, res.joined
      assert.same {s.id}, [s.id for s in *res.hosted.upcoming]
      assert.same nil, res.hosted.active
      assert.same nil, res.hosted.completed

    it "should get browse empty streaks", ->
      status, res = request_with_key "/api/1/streaks"
      assert.same {streaks: {}}, res

    it "should get browse empty streaks", ->
      s1 = factory.Streaks state: "before_start"
      s2 = factory.Streaks state: "after_end"
      s3 = factory.Streaks state: "during"

      status, res = request_with_key "/api/1/streaks"
      assert.same 3, #res.streaks

    it "should join streak", ->
      streak = factory.Streaks!
      status, res = request_with_key "/api/1/streak/#{streak.id}/join", post: {}
      assert.truthy res.joined

    it "should leave streak", ->
      streak = factory.Streaks!
      status, res = request_with_key "/api/1/streak/#{streak.id}/leave", post: {}
      assert.same false, res.left
      factory.StreakUsers user_id: current_user.id, streak_id: streak.id

      status, res = request_with_key "/api/1/streak/#{streak.id}/leave", post: {}
      assert.same true, res.left

    it "views streak", ->
      streak = factory.Streaks!
      status, res = request_with_key "/api/1/streak/#{streak.id}"
      assert.truthy res.streak

    it "views streak that user is in", ->
      streak = factory.Streaks!
      factory.StreakUsers streak_id: streak.id, user_id: current_user.id

      status, res = request_with_key "/api/1/streak/#{streak.id}"
      assert.truthy res.streak
      assert.truthy res.streak_user

    it "views streak submissions for empty streak", ->
      streak = factory.Streaks!
      status, res = request_with_key "/api/1/streak/#{streak.id}/submissions"
      assert.truthy res.submissions
      assert.same 0, #res.submissions

    it "views streak submissions", ->
      streak = factory.Streaks!
      factory.StreakSubmissions streak_id: streak.id
      factory.StreakSubmissions streak_id: streak.id

      status, res = request_with_key "/api/1/streak/#{streak.id}/submissions"
      assert.truthy res.submissions
      assert.same 2, #res.submissions

    it "views streak submissions with upload and like", ->
      streak = factory.Streaks!
      streak_sub = factory.StreakSubmissions streak_id: streak.id
      submission = streak_sub\get_submission!

      Uploads\create {
        user_id: current_user.id
        object_type: Uploads.object_types\for_db "submission"
        object_id: submission.id
        filename: "butt.png"
        ready: true
      }

      SubmissionLikes\create {
        submission_id: submission.id
        user_id: current_user.id
      }

      status, res = request_with_key "/api/1/streak/#{streak.id}/submissions"
      assert.truthy res.submissions
      assert.same 1, #res.submissions[1].uploads
      assert.truthy res.submissions[1].submission_like

