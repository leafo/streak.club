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


  it "should register user", ->
    status, res = request "/api/1/register", {
      post: {
        source: "ios"
        username: "leafo"
        password: "leafo"
        password_repeat: "leafo"
        email: "leafo@example.com"
      }
      expect: "json"
    }

    assert.truthy res.key
    assert.same 1, #Users\select!


  describe "with key", ->
    local api_key, current_user

    request_with_key = (url, opts={}) ->
      opts.get or= {}
      opts.get.key = api_key.key
      opts.expect = "json"
      request url, opts

    before_each ->
      api_key = factory.ApiKeys!
      current_user = api_key\get_user!

    it "should get empty my-streaks", ->
      status, res = request_with_key "/api/1/my-streaks"
      assert.same 200, status
      assert.same {
        hosted: {}
        joined: {}
      }, res


    it "should get my-streaks with joined streaks", ->
      s1 = factory.Streaks state: "before_start"
      s2 = factory.Streaks state: "after_end"
      s3 = factory.Streaks state: "during"

      for s in *{s1, s2}
        factory.StreakUsers user_id: current_user.id, streak_id: s.id

      status, res = request_with_key "/api/1/my-streaks"
      assert.same 200, status


      assert.same {}, res.hosted
      assert.same {s1.id}, [s.id for s in *res.joined.upcoming]
      assert.same {s2.id}, [s.id for s in *res.joined.completed]
      assert.same nil, res.joined.active

    it "should get my-streaks with hosted streaks", ->
      s = factory.Streaks state: "before_start", user_id: current_user.id
      status, res = request_with_key "/api/1/my-streaks"

      assert.same {}, res.joined
      assert.same {s.id}, [s.id for s in *res.hosted.upcoming]
      assert.same nil, res.hosted.active
      assert.same nil, res.hosted.completed

