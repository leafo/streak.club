import
  load_test_server
  close_test_server
  request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

import Streaks, Users from require "models"

factory = require "spec.factory"

describe "streaks", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Streaks, Users

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
    local streak
    before_each ->
      streak = factory.Streaks {
        start_date: "2015-3-1"
        end_date: "2015-4-5"
        hour_offset: -8
      }

    for h=8,20,4
      it "should truncate date on hour #{h}", ->
        d = streak\truncate_date date 2015, 3,1, h, 11
        expect = if h < 16
          "2015-02-28 16:00:00"
        else
          "2015-03-01 16:00:00"

        assert.same expect, d\fmt Streaks.timestamp_format_str
