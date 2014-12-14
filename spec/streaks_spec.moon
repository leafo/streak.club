import
  load_test_server
  close_test_server
  request
  from require "lapis.spec.server"

import truncate_tables from require "lapis.spec.db"

describe "streaks", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->

  it "should do something", ->
