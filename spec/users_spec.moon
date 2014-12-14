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
