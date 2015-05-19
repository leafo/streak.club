import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

import Streaks, Users, Submissions, StreakUsers, StreakSubmissions from require "models"

import request, request_as from require "spec.helpers"

date = require "date"

factory = require "spec.factory"

describe "streaks", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Streaks, Users, Submissions, StreakUsers, StreakSubmissions

  it "should create a streak from factory", ->
    streak = factory.Streaks!
    assert.truthy streak

  it "should recount a streak", ->
    streak = factory.Streaks!

    for i=1,2
      factory.StreakSubmissions streak_id: streak.id

    factory.StreakUsers streak_id: streak.id

    streak\recount!
    assert.same streak.users_count, 1
    assert.same streak.submissions_count, 2

  it "should create a streak from factory during", ->
    streak = factory.Streaks state: "during"
    assert.truthy streak\during!
    assert.falsy streak\before_start!
    assert.falsy streak\after_end!

  it "should create a streak from factory before start", ->
    streak = factory.Streaks state: "before_start"
    assert.falsy streak\during!
    assert.truthy streak\before_start!
    assert.falsy streak\after_end!

  it "should create a streak from factory after end", ->
    streak = factory.Streaks state: "after_end"
    assert.falsy streak\during!
    assert.falsy streak\before_start!
    assert.truthy streak\after_end!

  describe "with fixed streak UTC", ->
    local streak
    before_each ->
      streak = factory.Streaks {
        start_date: "2015-3-1"
        end_date: "2015-4-5"
      }

    for h=8,20,4
      it "should truncate date on hour #{h}", ->
        d = streak\truncate_date date 2015, 3,1, h, 11
        assert.same "2015-03-01 00:00:00", d\fmt Streaks.timestamp_format_str

  describe "with user", ->
    local current_user
    before_each ->
      current_user = factory.Users!

    streak_params = (override={}) ->
      p = {
        "streak[title]": "Streak world"
        "streak[short_description]": "This is my streak"
        "streak[description]": "Streak description here"
        "streak[hour_offset]": "0"
        "streak[start_date]": "2015-1-1"
        "streak[end_date]": "2015-2-1"
        "streak[publish_status]": "published"
        "streak[rate]": "daily"
        "streak[category]": "other"
        "streak[late_submit_type]": "public"
        "streak[membership_type]": "public"
        "timezone": "America/Los_Angeles"
      }

      for k,v in pairs override
        p[k] = v

      p

    it "should create streak", ->
      status, res = request_as current_user, "/streaks/new", {
        post: streak_params!
        expect: "json"
      }

      assert.same 200, status
      assert.falsy res.errors
      assert.truthy res.url

      assert.same 1, #Streaks\select!

      current_user\refresh!
      assert.same 1, current_user.streaks_count
      assert.same 0, current_user.hidden_streaks_count


    it "should create a hidden streak", ->
      status, res = request_as current_user, "/streaks/new", {
        post: streak_params {
          "streak[publish_status]": "hidden"
        }
        expect: "json"
      }

      assert.same 200, status
      assert.falsy res.errors

      current_user\refresh!
      assert.same 1, current_user.streaks_count
      assert.same 1, current_user.hidden_streaks_count

    it "should edit streak", ->
      streak = factory.Streaks user_id: current_user.id

      status, res = request_as current_user, "/streak/#{streak.id}/edit", {
        post: streak_params!
        expect: "json"
      }

      assert.same 200, status
      assert.falsy res.errors
      assert.truthy res.url

    it "should edit streak from public to hidden", ->
      streak = factory.Streaks user_id: current_user.id
      current_user\recount!

      status, res = request_as current_user, "/streak/#{streak.id}/edit", {
        post: streak_params {
          "streak[publish_status]": "hidden"
        }
        expect: "json"
      }

      assert.same 200, status
      assert.falsy res.errors
      assert.truthy res.url

      current_user\refresh!

      assert.same 1, current_user.streaks_count
      assert.same 1, current_user.hidden_streaks_count

    it "should not let stranger edit streak", ->
      streak = factory.Streaks user_id: current_user.id
      other_user = factory.Users!

      status, res = request_as other_user, "/streak/#{streak.id}/edit", {
        post: { }
      }

      assert.same 404, status

    it "should join streak", ->
      streak = factory.Streaks!
      status, res = request_as current_user, "/s/#{streak.id}/#{streak\slug!}", {
        post: {
          action: "join_streak"
        }
      }

      assert.same 302, status
      streak_user = assert unpack(StreakUsers\select!), "missing streak user"
      assert.same current_user.id, streak_user.user_id
      assert.same streak.id, streak_user.streak_id
      assert.same false, streak_user.pending

    it "should join streak members only streak with pending", ->
      streak = factory.Streaks membership_type: "members_only"
      status, res = request_as current_user, "/s/#{streak.id}/#{streak\slug!}", {
        post: {
          action: "join_streak"
        }
      }

      assert.same 302, status
      streak_user = assert unpack(StreakUsers\select!), "missing streak user"
      assert.same current_user.id, streak_user.user_id
      assert.same streak.id, streak_user.streak_id
      assert.same true, streak_user.pending


  describe "with fixed streak PST", ->
    local streak, user
    before_each ->
      user = factory.Users!
      streak = factory.Streaks {
        user_id: user.id
        start_date: "2015-3-1"
        end_date: "2015-4-5"
        hour_offset: -8
      }

    for h=0,23,4
      it "should truncate date on hour #{h}", ->
        d = streak\truncate_date date 2015, 3,1, h, 11
        expect = if h < 8
          "2015-02-28 08:00:00"
        else
          "2015-03-01 08:00:00"

        assert.same expect, d\fmt Streaks.timestamp_format_str

    for h=0,23,4
      it "should create streak submission on hour #{h}", ->
        submit_time = date(streak\start_datetime!)\addhours h
        submit = factory.StreakSubmissions {
          streak_id: streak.id
          submit_time: submit_time\fmt Streaks.timestamp_format_str
        }
        assert.same 1, submit\unit_number!

    for h=0,23,4
      it "should create streak submission on hour #{h} offset days", ->
        submit_time = date(streak\start_datetime!)\adddays(4)\addhours h
        submit = factory.StreakSubmissions {
          streak_id: streak.id
          submit_time: submit_time\fmt Streaks.timestamp_format_str
        }
        assert.same 5, submit\unit_number!


    streak_url = (streak) ->
      "/s/#{streak.id}/#{streak\slug!}"

    it "should view streak", ->
      status = request streak_url(streak)
      assert.same 200, status

    it "should view streak participants", ->
      status = request streak_url(streak) .. "/participants"
      assert.same 200, status

    it "should view streak stats", ->
      status = request streak_url(streak) .. "/stats"
      assert.same 200, status

    it "should view streak top submissions", ->
      status = request streak_url(streak) .. "/top-submissions"
      assert.same 200, status

    it "should view streak top streaks", ->
      status = request streak_url(streak) .. "/top-streaks"
      assert.same 200, status

    it "should view streak json page", ->
      status, res = request streak_url(streak) .. "?format=json", {
        expect: "json"
      }
      assert.same 200, status

    it "should view streak as owner", ->
      status = request_as user, streak_url(streak)
      assert.same 200, status

    it "should view first streak unit day", ->
      status = request "/streak/#{streak.id}/unit/2015-3-1"
      assert.same 200, status

    it "should view last streak unit day", ->
      status = request "/streak/#{streak.id}/unit/2015-4-5"
      assert.same 200, status

    describe "with submissions", ->
      before_each ->
        for i=1,2
          factory.StreakSubmissions {
            streak_id: streak.id
            submit_time: "2015-3-#{i} 09:00:00"
          }

      it "should view streak", ->
        status = request streak_url(streak)
        assert.same 200, status

      it "should view streak participants", ->
        status = request streak_url(streak) .. "/participants"
        assert.same 200, status

      it "should view streak json page", ->
        status, res = request streak_url(streak) .. "?format=json", {
          expect: "json"
        }
        assert.same 200, status

      it "should view streak json page 2", ->
        status, res = request streak_url(streak) .. "?format=json&page=2", {
          expect: "json"
        }
        assert.same 200, status

  describe "sampled streak", ->
    -- this is just a bunch of submissions I pulled from my dev db. Not testing
    -- anything specific, just trying to catch regressions in anything that I
    -- may not have written a test for

    it "should have correct unit counts", ->
      streak = factory.Streaks {
        start_date: "2014-12-02"
        end_date: "2015-12-31"
        hour_offset: -12
      }

      user1 = factory.StreakUsers streak_id: streak.id
      user2 = factory.StreakUsers streak_id: streak.id

      submit_times = {
        [user1]: {
          "2015-01-02 04:26:34"
          "2015-01-04 09:58:29"
          "2014-12-11 15:59:50"
          "2014-12-24 15:59:50"
          "2014-12-29 15:59:50"
          "2014-12-18 15:59:50"
          "2015-01-05 09:18:46"
          "2014-12-02 15:59:50"
          "2015-01-07 17:52:07"
          "2015-01-07 18:10:01"
          "2015-01-14 08:59:15"
          "2015-01-13 11:59:50"
          "2015-01-16 08:50:55"
          "2015-01-16 09:09:21"
          "2014-12-17 11:59:50"
          "2015-01-17 06:21:52"
          "2015-01-25 04:46:13"
          "2015-01-18 11:59:50"
        }

        [user2]: {
          "2015-01-25 22:09:17"
          "2015-01-11 11:59:50"
          "2015-01-10 11:59:50"
        }
      }

      for u, times in pairs submit_times
        for t in *times
          factory.StreakSubmissions {
            submit_time: t
            user_id: u.user_id
            streak_id: streak.id
          }

      counts = streak\unit_submission_counts!
      assert.same {
        "2014-12-02": 1
        "2014-12-11": 1
        "2014-12-16": 1
        "2014-12-18": 1
        "2014-12-24": 1
        "2014-12-29": 1
        "2015-01-01": 1
        "2015-01-03": 1
        "2015-01-04": 1
        "2015-01-07": 2
        "2015-01-09": 1
        "2015-01-10": 1
        "2015-01-12": 1
        "2015-01-13": 1
        "2015-01-15": 2
        "2015-01-16": 1
        "2015-01-17": 1
        "2015-01-24": 1
        "2015-01-25": 1
      }, counts

      u1_completed = {
        "2015-01-03", "2014-12-18", "2014-12-16", "2015-01-15", "2015-01-24",
        "2015-01-12", "2014-12-29", "2015-01-17", "2015-01-07", "2014-12-02",
        "2015-01-04", "2014-12-11", "2015-01-01", "2015-01-16", "2014-12-24",
        "2015-01-13"
      }

      u2_completed = {
        "2015-01-09", "2015-01-10", "2015-01-25"
      }

      assert.same {k, true for k in *u1_completed},
        {k, true for k in pairs user1\get_completed_units!}

      assert.same {k, true for k in *u2_completed},
        {k, true for k in pairs user2\get_completed_units!}

