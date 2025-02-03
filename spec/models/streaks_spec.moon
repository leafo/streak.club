date = require "date"
factory = require "spec.factory"

db = require "lapis.db"

describe "models.streaks", ->
  import Streaks, Users, Submissions, StreakUsers, StreakSubmissions from require "spec.models"

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

  describe "find_unsubmitted_users", ->
    it "gets empty unsubmitted users list for empty streak", ->
      streak = factory.Streaks state: "during"
      assert.same {}, streak\find_unsubmitted_users!

    it "gets every streak user when there are no submissions", ->
      other_streak = factory.Streaks state: "during"
      factory.StreakUsers streak_id: other_streak.id


      streak = factory.Streaks state: "during"
      su = factory.StreakUsers streak_id: streak.id

      unsubmitted = streak\find_unsubmitted_users!
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

      unsubmitted = streak\find_unsubmitted_users!
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

  describe "time functions", ->
    describe "daily unending", ->
      local streak

      before_each ->
        db = require "lapis.db"
        streak = factory.Streaks {
          start_date: "2019-1-10"
          end_date: db.NULL
          hour_offset: -8
          rate: "daily"
        }

      it "unit number for start date is 1", ->
        start = streak\start_datetime!
        assert.same 1, streak\unit_number_for_date start

      it "range between same date is 1", ->
        some_date = streak\start_datetime!\addhours 2922
        assert.same 1, streak\unit_span some_date, some_date

    describe "daily ending", ->
      local streak

      before_each ->
        db = require "lapis.db"
        streak = factory.Streaks {
          start_date: "2019-1-10"
          end_date: "2019-1-20"
          hour_offset: -8
          rate: "daily"
        }

      it "each_unit", ->
        units = [unit\fmt "%Y-%m-%d %H:%M:%S" for unit in streak\each_unit!]

        assert.same {
          "2019-01-10 08:00:00",
          "2019-01-11 08:00:00",
          "2019-01-12 08:00:00",
          "2019-01-13 08:00:00",
          "2019-01-14 08:00:00",
          "2019-01-15 08:00:00",
          "2019-01-16 08:00:00",
          "2019-01-17 08:00:00",
          "2019-01-18 08:00:00",
          "2019-01-19 08:00:00"
        }, units

      it "each_unit_in_range", ->
        do -- range before start and before end
          units = [unit\fmt "%Y-%m-%d %H:%M:%S" for unit in streak\each_unit_in_range "2019-1-1", "2019-1-15"]
          assert.same {
            "2019-01-10 08:00:00"
            "2019-01-11 08:00:00"
            "2019-01-12 08:00:00"
            "2019-01-13 08:00:00"
            "2019-01-14 08:00:00"
          }, units

        do -- exact range should return all units
          units = [unit\fmt "%Y-%m-%d %H:%M:%S" for unit in streak\each_unit_in_range "2019-01-10 08:00:00", "2019-01-19 08:00:00"]
          assert.same {
            "2019-01-10 08:00:00",
            "2019-01-11 08:00:00",
            "2019-01-12 08:00:00",
            "2019-01-13 08:00:00",
            "2019-01-14 08:00:00",
            "2019-01-15 08:00:00",
            "2019-01-16 08:00:00",
            "2019-01-17 08:00:00",
            "2019-01-18 08:00:00",
            "2019-01-19 08:00:00"
          }, units

        do -- range extends past end of streak
          units = [unit\fmt "%Y-%m-%d %H:%M:%S" for unit in streak\each_unit_in_range "2019-01-16", "2019-01-30"]
          assert.same {
            "2019-01-16 08:00:00",
            "2019-01-17 08:00:00",
            "2019-01-18 08:00:00",
            "2019-01-19 08:00:00"
          }, units

    describe "weekly", ->
      local streak

      before_each ->
        db = require "lapis.db"
        streak = factory.Streaks {
          start_date: "2019-1-10"
          end_date: db.NULL
          hour_offset: -8
          rate: "weekly"
        }

      it "unit number for start date is 1", ->
        start = streak\start_datetime!
        assert.same 1, streak\unit_number_for_date start

      it "range between same date is 1", ->
        some_date = streak\start_datetime!\addhours 2922
        assert.same 1, streak\unit_span some_date, some_date

    describe "monthly", ->
      local streak

      before_each ->
        db = require "lapis.db"
        streak = factory.Streaks {
          start_date: "2019-1-10"
          end_date: db.NULL
          hour_offset: -8
          rate: "monthly"
        }

      it "unit_number_for_date", ->
        start = streak\start_datetime!
        assert.same 1, streak\unit_number_for_date start

      it "range between same date is 1", ->
        some_date = streak\start_datetime!\addhours 2922
        assert.same 1, streak\unit_span some_date, some_date

      it "gets range across boundary", ->
        left = streak\local_to_utc "2019-4-9"
        right = streak\local_to_utc "2019-4-10"
        right2 = streak\local_to_utc "2019-4-11"

        assert.same 2, streak\unit_span left, right
        assert.same 2, streak\unit_span left, right2

      it "gets range within unit", ->
        left = streak\local_to_utc "2019-4-8"
        right = streak\local_to_utc "2019-4-9"
        right2 = streak\local_to_utc "2019-4-10"

        assert.same 1, streak\unit_span left, right
        assert.same 2, streak\unit_span left, right2
        assert.same 1, streak\unit_span left, right2\addseconds -1

      it "gets range over many unit", ->
        left = streak\local_to_utc "2019-1-11"
        right = streak\local_to_utc "2019-7-9"

        assert.same 6, streak\unit_span left, right
        assert.same 7, streak\unit_span left, date(right)\adddays 3

      it "gets each unit in utc", ->
        k = 0
        dates = for unit in streak\each_unit!
          k += 1
          if k > 5
            break
          else
            unit\fmt "%Y-%m-%d %H:%M:%S"

        assert.same dates, {
          "2019-01-10 08:00:00"
          "2019-02-10 08:00:00"
          "2019-03-10 08:00:00"
          "2019-04-10 08:00:00"
          "2019-05-10 08:00:00"
        }

      it "truncate_date", ->
        d = streak\local_to_utc "2019-4-9"

        assert.same "2019-03-10 08:00:00",
          tostring streak\truncate_date(d)\fmt "%Y-%m-%d %H:%M:%S"

        d = streak\local_to_utc("2019-4-10")\addhours 5

        assert.same "2019-04-10 08:00:00",
          tostring streak\truncate_date(d)\fmt "%Y-%m-%d %H:%M:%S"

  describe "streak submit unit group field", ->
    it "calculates start unit for monthly #ddd", ->
      streak = factory.Streaks {
        start_date: "2021-10-24"
        hour_offset: -7
        rate: "monthly"
      }

      submit_time = "2023-05-09 06:11:08"
      expected_submit_day = "2023-05-23 00:00:00"

      res = unpack db.query [[
        select submit_time, ? from (values
          (?::timestamp without time zone)
        ) as submission(submit_time)
      ]], db.raw(streak\_streak_submit_unit_group_field!), submit_time

      assert.same expected_submit_day, res.submit_day











