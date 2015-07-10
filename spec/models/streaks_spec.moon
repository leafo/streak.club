import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Streaks, Users, Submissions,
  StreakUsers, StreakSubmissions from require "models"

date = require "date"
factory = require "spec.factory"

describe "models.streaks", ->
  use_test_env!

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

  describe "unsubmitted_users", ->
    it "gets empty unsubmitted users list for empty streak", ->
      streak = factory.Streaks state: "during"
      assert.same {}, streak\unsubmitted_users!

    it "gets every streak user when there are no submissions", ->
      other_streak = factory.Streaks state: "during"
      factory.StreakUsers streak_id: other_streak.id


      streak = factory.Streaks state: "during"
      su = factory.StreakUsers streak_id: streak.id

      unsubmitted = streak\unsubmitted_users!
      assert.same 1, #unsubmitted

      for _su in *unsubmitted
        assert.same streak.id, _su.streak_id
        assert.same su.user_id, _su.user_id

    it "gets only streak users who have not submitted", ->
      other_streak = factory.Streaks state: "during"
      factory.StreakUsers streak_id: other_streak.id

      streak = factory.Streaks state: "during"
      su1 = factory.StreakUsers streak_id: streak.id

      su2 = factory.StreakUsers streak_id: streak.id
      factory.StreakSubmissions streak_id: streak.id, user_id: su2.user_id

      unsubmitted = streak\unsubmitted_users!
      assert.same 1, #unsubmitted

      for _su in *unsubmitted
        assert.same streak.id, _su.streak_id
        assert.same su1.user_id, _su.user_id

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

  it "finds streaks ending soon when there are no streaks", ->
    assert.same {}, Streaks\find_streaks_ending_soon!

  it "finds streaks ending soon", ->
    hour = date(true)\gethours!
    offset = -(hour + 1)

    factory.Streaks state: "before_start", hour_offset: offset
    factory.Streaks state: "after_end", hour_offset: offset
    d = factory.Streaks state: "during", hour_offset: offset
    factory.Streaks state: "during", hour_offset: -(hour + 5)

    assert.same {d.id}, [s.id for s in *Streaks\find_streaks_ending_soon!]

