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

  it "should create a streak", ->
    streak = factory.Streaks!
    assert.truthy streak

  it "should create a streak during", ->
    streak = factory.Streaks state: "during"
    assert.truthy streak\during!
    assert.falsy streak\before_start!
    assert.falsy streak\after_end!

  it "should create a streak before start", ->
    streak = factory.Streaks state: "before_start"
    assert.falsy streak\during!
    assert.truthy streak\before_start!
    assert.falsy streak\after_end!

  it "should create a streak after end", ->
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


    it "should view streak", ->
      for i=1,2
        factory.StreakSubmissions {
          streak_id: streak.id
          submit_time: "2015-3-#{i} 09:00:00"
        }

      status = request "/streak/#{streak.id}"
      assert.same 200, status

    it "should view streak as owner", ->
      status = request_as user, "/streak/#{streak.id}"
      assert.same 200, status

    it "should view first streak unit day", ->
      status = request "/streak/#{streak.id}/unit/2015-3-1"
      assert.same 200, status

    it "should view last streak unit day", ->
      status = request "/streak/#{streak.id}/unit/2015-4-5"
      assert.same 200, status
