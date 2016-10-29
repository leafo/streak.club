import use_test_server from require "lapis.spec"

import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "applications.streaks", ->
  use_test_server!

  import Streaks, Users, StreakUsers from require "spec.models"

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

