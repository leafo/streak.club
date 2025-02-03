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
    it "monthly streak submissions", ->
      test_data = {
        {
          streak_data: {
            end_date: "2020-01-01"
            hour_offset: 11
            rate: "monthly"
            start_date: "2019-01-01"
          }
          submissions: {
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-21 21:59:58" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-29 09:48:31" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-30 20:34:51" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-31 04:32:27" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-31 07:59:48" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-31 08:49:13" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-31 09:34:26" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-31 09:39:31" }
            { expected_day: "2019-02-01 00:00:00", submit_time: "2019-02-25 21:03:49" }
            { expected_day: "2019-03-01 00:00:00", submit_time: "2019-02-28 21:48:31" }
            { expected_day: "2019-03-01 00:00:00", submit_time: "2019-03-03 12:59:50" }
            { expected_day: "2019-03-01 00:00:00", submit_time: "2019-03-28 17:45:14" }
            { expected_day: "2019-04-01 00:00:00", submit_time: "2019-04-07 07:18:30" }
            { expected_day: "2019-04-01 00:00:00", submit_time: "2019-04-27 23:56:57" }
            { expected_day: "2019-05-01 00:00:00", submit_time: "2019-05-27 21:52:33" }
            { expected_day: "2019-05-01 00:00:00", submit_time: "2019-05-30 21:34:14" }
            { expected_day: "2019-06-01 00:00:00", submit_time: "2019-06-06 08:47:21" }
            { expected_day: "2019-06-01 00:00:00", submit_time: "2019-06-24 02:36:02" }
            { expected_day: "2019-06-01 00:00:00", submit_time: "2019-06-29 17:40:18" }
            { expected_day: "2019-07-01 00:00:00", submit_time: "2019-07-09 10:43:39" }
            { expected_day: "2019-07-01 00:00:00", submit_time: "2019-07-30 12:59:50" }
            { expected_day: "2019-07-01 00:00:00", submit_time: "2019-07-30 21:45:51" }
            { expected_day: "2019-07-01 00:00:00", submit_time: "2019-07-31 00:14:22" }
            { expected_day: "2019-08-01 00:00:00", submit_time: "2019-08-09 18:44:43" }
            { expected_day: "2019-08-01 00:00:00", submit_time: "2019-08-31 08:41:40" }
            { expected_day: "2019-09-01 00:00:00", submit_time: "2019-09-14 06:48:51" }
            { expected_day: "2019-10-01 00:00:00", submit_time: "2019-10-19 16:23:02" }
            { expected_day: "2019-11-01 00:00:00", submit_time: "2019-11-01 23:46:51" }
            { expected_day: "2019-11-01 00:00:00", submit_time: "2019-11-25 20:38:00" }
            { expected_day: "2019-12-01 00:00:00", submit_time: "2019-12-09 20:31:28" }
            { expected_day: "2019-12-01 00:00:00", submit_time: "2019-12-16 20:50:30" }
          }
        }
        {
          streak_data: {
            end_date: "2019-01-02"
            hour_offset: -8
            rate: "monthly"
            start_date: "2019-01-01"
          }
          submissions: {
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-25 07:59:50" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-26 07:59:50" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-27 07:59:50" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-28 07:59:50" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-29 07:59:50" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-30 07:59:50" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-01-31 07:59:50" }
            { expected_day: "2019-01-01 00:00:00", submit_time: "2019-02-01 07:59:50" }
            { expected_day: "2019-02-01 00:00:00", submit_time: "2019-02-02 07:59:50" }
            { expected_day: "2019-02-01 00:00:00", submit_time: "2019-02-03 07:59:50" }
            { expected_day: "2019-02-01 00:00:00", submit_time: "2019-02-03 11:11:49" }
          }
        }
        {
          streak_data: {
            hour_offset: 5
            rate: "monthly"
            start_date: "2019-09-25"
          }
          submissions: {
            { expected_day: "2019-09-25 00:00:00", submit_time: "2019-09-25 07:06:11" }
          }
        }
        {
          streak_data: {
            hour_offset: -8
            rate: "monthly"
            start_date: "2020-01-01"
          }
          submissions: {
            { expected_day: "2020-01-01 00:00:00", submit_time: "2020-01-12 19:16:13" }
          }
        }
        {
          streak_data: {
            hour_offset: -8
            rate: "monthly"
            start_date: "2020-01-01"
          }
          submissions: {
            { expected_day: "2020-01-01 00:00:00", submit_time: "2020-01-17 07:39:41" }
            { expected_day: "2020-02-01 00:00:00", submit_time: "2020-02-19 23:47:19" }
            { expected_day: "2020-05-01 00:00:00", submit_time: "2020-05-05 09:46:48" }
            { expected_day: "2020-07-01 00:00:00", submit_time: "2020-07-06 08:33:24" }
          }
        }
        {
          streak_data: {
            hour_offset: -6
            rate: "monthly"
            start_date: "2020-03-21"
          }
          submissions: {
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-22 04:24:13" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-23 04:40:09" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-24 05:01:45" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-25 01:33:01" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-26 05:19:36" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-27 04:56:31" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-28 05:26:51" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-29 05:18:19" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-30 04:50:57" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-03-31 04:38:13" }
            { expected_day: "2020-03-21 00:00:00", submit_time: "2020-04-01 05:38:18" }
          }
        }
        {
          streak_data: {
            end_date: "2030-01-01"
            hour_offset: -6
            rate: "monthly"
            start_date: "2020-04-01"
          }
          submissions: {
            { expected_day: "2020-04-01 00:00:00", submit_time: "2020-04-21 02:29:51" }
            { expected_day: "2020-04-01 00:00:00", submit_time: "2020-04-21 03:00:48" }
            { expected_day: "2020-04-01 00:00:00", submit_time: "2020-04-26 11:54:33" }
            { expected_day: "2020-04-01 00:00:00", submit_time: "2020-04-29 16:42:53" }
            { expected_day: "2020-04-01 00:00:00", submit_time: "2020-04-30 00:35:54" }
            { expected_day: "2020-04-01 00:00:00", submit_time: "2020-05-01 04:54:18" }
            { expected_day: "2020-07-01 00:00:00", submit_time: "2020-07-31 17:33:17" }
            { expected_day: "2020-08-01 00:00:00", submit_time: "2020-08-22 09:56:40" }
            { expected_day: "2020-08-01 00:00:00", submit_time: "2020-08-31 21:02:58" }
          }
        }
        {
          streak_data: {
            hour_offset: 5
            rate: "monthly"
            start_date: "2020-06-04"
          }
          submissions: {
            { expected_day: "2020-06-04 00:00:00", submit_time: "2020-06-06 03:41:47" }
          }
        }
        {
          streak_data: {
            end_date: "2022-04-09"
            hour_offset: 0
            rate: "monthly"
            start_date: "2020-06-08"
          }
          submissions: {
            { expected_day: "2020-06-08 00:00:00", submit_time: "2020-06-08 07:09:08" }
            { expected_day: "2020-06-08 00:00:00", submit_time: "2020-06-09 02:57:46" }
            { expected_day: "2020-06-08 00:00:00", submit_time: "2020-06-15 05:24:38" }
            { expected_day: "2020-06-08 00:00:00", submit_time: "2020-06-20 02:41:57" }
            { expected_day: "2020-06-08 00:00:00", submit_time: "2020-06-28 06:43:53" }
            { expected_day: "2020-06-08 00:00:00", submit_time: "2020-06-28 16:59:50" }
            { expected_day: "2020-07-07 00:00:00", submit_time: "2020-07-05 12:15:20" }
            { expected_day: "2020-07-08 00:00:00", submit_time: "2020-07-12 05:59:07" }
            { expected_day: "2020-07-08 00:00:00", submit_time: "2020-07-19 12:24:41" }
            { expected_day: "2020-07-08 00:00:00", submit_time: "2020-07-26 16:59:50" }
            { expected_day: "2020-08-07 00:00:00", submit_time: "2020-08-02 08:16:32" }
            { expected_day: "2020-08-08 00:00:00", submit_time: "2020-08-09 16:57:04" }
            { expected_day: "2020-08-08 00:00:00", submit_time: "2020-08-16 06:49:25" }
            { expected_day: "2020-08-08 00:00:00", submit_time: "2020-08-23 16:59:10" }
            { expected_day: "2020-08-08 00:00:00", submit_time: "2020-08-30 20:28:03" }
            { expected_day: "2020-09-07 00:00:00", submit_time: "2020-09-06 17:26:26" }
            { expected_day: "2020-09-08 00:00:00", submit_time: "2020-09-13 23:05:56" }
            { expected_day: "2020-09-08 00:00:00", submit_time: "2020-09-20 23:47:22" }
            { expected_day: "2020-09-08 00:00:00", submit_time: "2020-09-27 23:30:23" }
            { expected_day: "2020-10-07 00:00:00", submit_time: "2020-10-04 23:27:30" }
            { expected_day: "2020-10-08 00:00:00", submit_time: "2020-10-11 23:48:08" }
            { expected_day: "2020-10-08 00:00:00", submit_time: "2020-10-18 23:45:36" }
            { expected_day: "2020-10-08 00:00:00", submit_time: "2020-10-25 23:46:42" }
            { expected_day: "2020-11-07 00:00:00", submit_time: "2020-11-01 23:59:50" }
            { expected_day: "2020-11-08 00:00:00", submit_time: "2020-11-08 23:59:50" }
            { expected_day: "2020-11-08 00:00:00", submit_time: "2020-11-15 23:59:50" }
            { expected_day: "2020-11-08 00:00:00", submit_time: "2020-11-22 23:59:50" }
            { expected_day: "2020-11-08 00:00:00", submit_time: "2020-11-29 23:59:50" }
            { expected_day: "2020-12-07 00:00:00", submit_time: "2020-12-06 23:55:24" }
            { expected_day: "2020-12-08 00:00:00", submit_time: "2020-12-13 23:57:33" }
            { expected_day: "2021-02-07 00:00:00", submit_time: "2021-02-06 21:03:37" }
            { expected_day: "2021-03-07 00:00:00", submit_time: "2021-03-07 22:19:12" }
          }
        }
        {
          streak_data: {
            end_date: "2021-12-31"
            hour_offset: 8
            rate: "monthly"
            start_date: "2021-01-01"
          }
          submissions: {
            { expected_day: "2021-01-01 00:00:00", submit_time: "2021-01-07 07:22:24" }
            { expected_day: "2021-01-01 00:00:00", submit_time: "2021-01-31 06:09:17" }
            { expected_day: "2021-01-01 00:00:00", submit_time: "2021-01-31 15:57:27" }
            { expected_day: "2021-02-01 00:00:00", submit_time: "2021-02-06 06:00:48" }
            { expected_day: "2021-02-01 00:00:00", submit_time: "2021-02-28 05:52:31" }
            { expected_day: "2021-03-01 00:00:00", submit_time: "2021-03-16 20:03:15" }
            { expected_day: "2021-03-01 00:00:00", submit_time: "2021-03-30 03:48:44" }
            { expected_day: "2021-04-01 00:00:00", submit_time: "2021-03-31 18:15:09" }
            { expected_day: "2021-04-01 00:00:00", submit_time: "2021-04-26 02:34:36" }
            { expected_day: "2021-04-01 00:00:00", submit_time: "2021-04-30 08:54:34" }
            { expected_day: "2021-05-01 00:00:00", submit_time: "2021-05-28 21:41:27" }
          }
        }
        {
          streak_data: {
            hour_offset: -7
            rate: "monthly"
            start_date: "2021-10-24"
          }
          submissions: {
            { expected_day: "2023-05-23 00:00:00", submit_time: "2023-05-09 06:11:08" }
          }
        }
        {
          streak_data: {
            hour_offset: -6
            rate: "monthly"
            start_date: "2022-12-01"
          }
          submissions: {
            { expected_day: "2022-12-01 00:00:00", submit_time: "2022-12-30 23:20:31" }
            { expected_day: "2022-12-01 00:00:00", submit_time: "2022-12-31 04:52:16" }
            { expected_day: "2022-12-01 00:00:00", submit_time: "2022-12-31 23:48:26" }
            { expected_day: "2022-12-01 00:00:00", submit_time: "2023-01-01 01:27:24" }
            { expected_day: "2023-01-01 00:00:00", submit_time: "2023-01-04 23:37:10" }
            { expected_day: "2023-01-01 00:00:00", submit_time: "2023-01-27 16:07:38" }
            { expected_day: "2023-03-01 00:00:00", submit_time: "2023-03-01 23:41:26" }
            { expected_day: "2023-04-01 00:00:00", submit_time: "2023-05-01 05:47:15" }
            { expected_day: "2023-07-01 00:00:00", submit_time: "2023-07-12 14:05:53" }
          }
        }
        {
          streak_data: {
            hour_offset: -9
            rate: "monthly"
            start_date: "2023-05-06"
          }
          submissions: {
            { expected_day: "2023-05-06 00:00:00", submit_time: "2023-05-06 21:03:43" }
            { expected_day: "2023-05-06 00:00:00", submit_time: "2023-05-14 03:57:36" }
            { expected_day: "2023-05-06 00:00:00", submit_time: "2023-05-21 03:53:44" }
            { expected_day: "2023-05-06 00:00:00", submit_time: "2023-05-27 18:16:05" }
            { expected_day: "2023-06-06 00:00:00", submit_time: "2023-06-09 18:19:41" }
            { expected_day: "2023-06-06 00:00:00", submit_time: "2023-06-10 20:03:28" }
            { expected_day: "2023-06-06 00:00:00", submit_time: "2023-06-17 18:36:44" }
            { expected_day: "2023-06-06 00:00:00", submit_time: "2023-06-24 20:22:51" }
            { expected_day: "2023-07-06 00:00:00", submit_time: "2023-07-07 03:29:42" }
            { expected_day: "2023-07-06 00:00:00", submit_time: "2023-07-09 20:53:11" }
            { expected_day: "2023-07-06 00:00:00", submit_time: "2023-07-17 20:41:52" }
            { expected_day: "2023-07-06 00:00:00", submit_time: "2023-07-23 00:38:26" }
            { expected_day: "2023-07-06 00:00:00", submit_time: "2023-07-29 13:26:24" }
            { expected_day: "2023-08-05 00:00:00", submit_time: "2023-08-05 17:58:03" }
            { expected_day: "2023-08-06 00:00:00", submit_time: "2023-08-12 14:43:51" }
          }
        }
        {
          streak_data: {
            hour_offset: -8
            rate: "monthly"
            start_date: "2023-12-26"
          }
          submissions: {
            { expected_day: "2023-12-26 00:00:00", submit_time: "2023-12-26 21:10:33" }
          }
        }
        {
          streak_data: {
            hour_offset: -10
            rate: "monthly"
            start_date: "2024-04-05"
          }
          submissions: {
            { expected_day: "2024-04-05 00:00:00", submit_time: "2024-04-05 21:42:46" }
          }
        }
        {
          streak_data: {
            end_date: "2025-12-31"
            hour_offset: 1
            rate: "monthly"
            start_date: "2025-01-31"
          }
          submissions: {
            { expected_day: "2025-01-30 00:00:00", submit_time: "2025-01-01 21:07:02" }
            { expected_day: "2025-01-31 00:00:00", submit_time: "2025-01-31 17:08:10" }
            { expected_day: "2025-01-31 00:00:00", submit_time: "2025-01-31 17:15:02" }
            { expected_day: "2025-01-31 00:00:00", submit_time: "2025-01-31 18:09:47" }
            { expected_day: "2025-01-31 00:00:00", submit_time: "2025-01-31 21:31:57" }
            { expected_day: "2025-01-31 00:00:00", submit_time: "2025-01-31 22:38:25" }


            { submit_time: "2025-02-01 00:42:30", expected_day: "2025-03-02 00:00:00" }
            { submit_time: "2025-02-01 03:07:26", expected_day: "2025-03-02 00:00:00" }
          }
        }
      }

      import types from require "tableshape"
      load_streak = types.partial {
        rate: types.string / Streaks.rates\for_db
      }

      for data in *test_data
        streak = Streaks\load load_streak\transform data.streak_data

        submission_times = db.array [s.submit_time for s in *data.submissions]
        continue unless next submission_times

        res = db.query [[
          select submit_time, ? from unnest(?::timestamp without time zone[]) as submission(submit_time)
        ]], db.raw(streak\_streak_submit_unit_group_field!), submission_times

        for idx, row in ipairs res
          assert.same data.submissions[idx].expected_day, row.submit_day,
            "Submission #{data.submissions[idx].submit_time} for Streak #{streak.start_date} #{streak.hour_offset}"
