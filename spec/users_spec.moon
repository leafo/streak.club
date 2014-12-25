import
  load_test_server
  close_test_server
  request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

factory = require "spec.factory"
import Users from require "models"

describe "users", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users

  it "should create a user", ->
    factory.Users!

  it "should load login", ->
    status, res = request "/login"
    assert.same 200, status

  it "should view user profile", ->
    user = factory.Users!
    status, res = request "/u/#{user.slug}"
    assert.same 200, status

