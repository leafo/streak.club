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

  it "should find followers", ->
    user = factory.Users!

    followers = for i=1,2
      factory.Followings dest_user_id: user.id

    factory.Followings source_user_id: user.id

    pager = user\find_followers!
    assert.same 2, pager\total_items!

    users = pager\get_page!
    user_ids = {u.id, true for u in *users}
    assert.same {f.source_user_id, true for f in *followers}, user_ids

  it "should find following", ->
    user = factory.Users!

    following = for i=1,2
      factory.Followings source_user_id: user.id

    factory.Followings dest_user_id: user.id

    pager = user\find_following!
    assert.same 2, pager\total_items!

    users = pager\get_page!
    user_ids = {u.id, true for u in *users}
    assert.same {f.dest_user_id, true for f in *following}, user_ids


  describe "with user", ->
    local user

    before_each ->
      user = factory.Users!

    it "should load empty followers page", ->
      request_as nil, "/u/#{user.slug}/followers"
      request_as user, "/u/#{user.slug}/followers"

    it "should load empty following page", ->
      request_as nil, "/u/#{user.slug}/following"
      request_as user, "/u/#{user.slug}/following"

    describe "with followers/following", ->
      before_each ->
        for i=1,2
          factory.Followings source_user_id: user.id
          factory.Followings dest_user_id: user.id

      it "should load empty followers page", ->
        request_as nil, "/u/#{user.slug}/followers"
        request_as user, "/u/#{user.slug}/followers"

      it "should load empty following page", ->
        request_as nil, "/u/#{user.slug}/following"
        request_as user, "/u/#{user.slug}/following"

