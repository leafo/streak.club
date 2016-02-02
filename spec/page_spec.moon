import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import request, request_as from require "spec.helpers"

import truncate_tables from require "lapis.spec.db"
import Users, UserProfiles, Streaks, Submissions from require "models"

factory = require "spec.factory"

describe "page", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, UserProfiles, Streaks, Submissions

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


