import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"
import request, request_as from require "spec.helpers"

import Streaks, Users, Submissions, StreakUsers, StreakSubmissions from require "models"

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
    assert.same 200, status


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
      }

      assert.same {
        errors: { "you must choose a streak to submit to" }
      }, res

    it "should not allow submission to unrelated streak", ->
      other_streak = factory.Streaks!

      status, res = do_submit {
        ["submit_to[#{other_streak.id}]"]: "yes"
        "submission[title]": ""
      }

      assert.same {
        errors: { "you must choose a streak to submit to" }
      }, res

    it "should submit a blank submission", ->
      status, res = do_submit {
        ["submit_to[#{streak.id}]"]: "yes"
        "submission[title]": ""
      }
      assert.truthy res.success

    it "should submit to multiple streaks", ->
      status, res = do_submit {
        ["submit_to[#{streak.id}]"]: "yes"
        "submission[title]": ""
      }
      assert.truthy res.success


    it "should not allow submission to streak already submitted to", ->
      factory.StreakSubmissions streak_id: streak.id, user_id: current_user.id

      status, res = do_submit {
        ["submit_to[#{streak.id}]"]: "yes"
        "submission[title]": ""
      }

      error res

