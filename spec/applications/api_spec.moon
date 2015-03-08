import
  load_test_server
  close_test_server
  request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"
import ApiKeys, Users, Streaks, StreakUsers from require "models"

factory = require "spec.factory"

describe "api", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, ApiKeys

  it "it should create api key", ->
    assert factory.ApiKeys!

