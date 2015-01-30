import
  load_test_server
  close_test_server
  from require "lapis.spec.server"

import request_as from require "spec.helpers"
import truncate_tables from require "lapis.spec.db"

import Users, Followings from require "models"

factory = require "spec.factory"

describe "followers", ->
  setup ->
    load_test_server!

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, Followings

  it "should create a following", ->
    f = assert factory.Followings!

    source = f\get_source_user!
    assert.same 0, source.followers_count
    assert.same 1, source.following_count

    dest = f\get_dest_user!
    assert.same 1, dest.followers_count
    assert.same 0, dest.following_count


