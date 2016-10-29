import use_test_server from require "lapis.spec"
import request_as from require "spec.helpers"

factory = require "spec.factory"

describe "applications.community", ->
  use_test_server!

  import Streaks, Users, StreakUsers from require "spec.models"
  import Categories, Posts, Topics, CommunityUsers from require "spec.community_models"

  it "loads empty community for streak", ->
    streak = factory.Streaks!
    user = streak\get_user!
    status = request_as nil, "/s/#{streak.id}/#{streak\slug!}/discussion"
    assert.same 200, status


  describe "with topic", ->
    local streak, category, topic, post

    before_each ->
      streak = factory.Streaks!
      category = factory.community.Categories streak: streak
      topic = factory.community.Topics category_id: category.id

      post = factory.community.Posts topic_id: topic.id
      topic\increment_from_post post

    it "loads community for streak with topics", ->
      status = request_as nil, "/s/#{streak.id}/#{streak\slug!}/discussion"
      assert.same 200, status

    it "views topic", ->
      status = request_as nil, "/t/#{topic.id}/#{topic.slug}"
      assert.same 200, status

    it "views post", ->
      status = request_as nil, "/post/#{post.id}"
      assert.same 200, status

    it "views delete topic", ->
      post_user = post\get_user!
      status = request_as post_user, "/post/#{post.id}/delete"
      assert.same 200, status

      other_user = factory.Users!
      status = request_as nil, "/post/#{post.id}/delete"
      assert.same 404, status

      other_user = factory.Users!
      status = request_as other_user, "/post/#{post.id}/delete"
      assert.same 404, status

    it "views delete post", ->
      other_post = factory.community.Posts topic_id: topic.id
      topic\increment_from_post other_post

      post_user = other_post\get_user!
      status = request_as post_user, "/post/#{other_post.id}/delete"
      assert.same 200, status

      -- not allowed to view
      status = request_as nil, "/post/#{other_post.id}/delete"
      assert.same 404, status

      status = request_as post\get_user!, "/post/#{other_post.id}/delete"
      assert.same 404, status

    it "views edit topic", ->
      post_user = post\get_user!
      status = request_as post_user, "/post/#{post.id}/edit"
      assert.same 200, status

      other_user = factory.Users!
      status = request_as other_user, "/post/#{post.id}/edit"
      assert.same 404, status

      status = request_as nil, "/post/#{post.id}/edit"
      assert.same 404, status

    it "views edit post", ->
      other_post = factory.community.Posts topic_id: topic.id
      topic\increment_from_post other_post

      post_user = other_post\get_user!
      status = request_as post_user, "/post/#{other_post.id}/edit"
      assert.same 200, status

      other_user = factory.Users!
      status = request_as other_user, "/post/#{other_post.id}/edit"
      assert.same 404, status

      status = request_as nil, "/post/#{other_post.id}/edit"
      assert.same 404, status


