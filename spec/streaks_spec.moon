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

