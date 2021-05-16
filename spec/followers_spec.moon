import use_test_server from require "lapis.spec"
import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "followers", ->
  use_test_server!

  import Users, Followings from require "spec.models"

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

  it "follows user", ->
    user = factory.Users!
    other_user = factory.Users!

    status, res = request_as user, "/user/#{other_user.id}/follow", {
      post: {}
      expect: "json"
    }

    assert.same 200, status
    assert.falsy res.errors
    followings = Followings\select!
    assert.same 1, #followings
    assert.same user.id, followings[1].source_user_id
    assert.same other_user.id, followings[1].dest_user_id

  it "unfollows user", ->
    f = factory.Followings!
    status, res = request_as f\get_source_user!, "/user/#{f\get_dest_user!.id}/unfollow", {
      post: {}
      expect: "json"
    }

    assert.same 0, #Followings\select!

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

