import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import request_as from require "spec.helpers"
import truncate_tables from require "lapis.spec.db"
import Streaks, Users, StreakUsers from require "models"

factory = require "spec.factory"

describe "applications.streaks", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Streaks, Users, StreakUsers

  it "should browse empty streaks", ->
    status, res = request_as nil, "/streaks"
    assert.same 200, status

  describe "with streaks", ->
    before_each ->
      for state in *{"during", "before_start", "after_end"}
        factory.Streaks :state

    it "should browse streaks", ->
      status, res = request_as nil, "/streaks"
      assert.same 200, status

