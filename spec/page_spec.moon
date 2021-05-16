import use_test_server from require "lapis.spec"
import request, request_as from require "spec.helpers"

factory = require "spec.factory"

describe "page", ->
  use_test_server!
  import Users, UserProfiles, Streaks, Submissions from require "spec.models"

  should_load = (path) ->
    it "should load #{path}", ->
      status, res = request path
      assert.same 200, status

  should_load_logged_in = (path) ->
    it "should load #{path}", ->
      user = factory.Users!
      status, res = request_as user, path
      assert.same 200, status

  should_load "/"
  should_load "/streaks"
  should_load "/stats"
  should_load "/stats/this-week"
  should_load "/login"
  should_load "/register"

  should_load_logged_in "/"


