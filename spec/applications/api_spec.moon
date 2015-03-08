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

  it "it should log in user", ->
    user = factory.Users username: "leafo", password: "leafo"
    status, res = request "/api/1/login", {
      post: {
        source: "ios"
        username: "leafo"
        password: "leafo"
      }
      expect: "json"
    }

    assert.same 200, status
    key = assert res.key
    assert.same ApiKeys.sources.ios, key.source
    assert.same user.id, key.user_id

    -- try again, re-use key
    status, res = request "/api/1/login", {
      post: {
        source: "ios"
        username: "leafo"
        password: "leafo"
      }
      expect: "json"
    }

    assert.same key, res.key

