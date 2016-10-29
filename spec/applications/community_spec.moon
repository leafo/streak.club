import use_test_server from require "lapis.spec"
import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "applications.community", ->
  use_test_server!

  import Streaks, Users, StreakUsers from require "spec.models"

  it "loads empty community for streak", ->
    streak = factory.Streaks!
    user = streak\get_user!
    status = request_as nil, "/s/#{streak.id}/#{streak\slug!}/discussion"
    assert.same 200, status


