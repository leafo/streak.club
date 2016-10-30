import use_test_env from require "lapis.spec"

factory = require "spec.factory"

describe "models.posts", ->
  use_test_env!

  import Streaks, Users, StreakUsers from require "spec.models"
  import Categories, Posts, Topics, CommunityUsers from require "spec.community_models"

  describe "notification_targets", ->
    local streak, category, topic, post

    before_each ->
      streak = factory.Streaks!
      category = factory.community.Categories streak: streak
      topic = factory.community.Topics category_id: category.id

      post = factory.community.Posts {
        topic_id: topic.id
        user_id: topic.user_id
      }

      topic\increment_from_post post

    flatten_targets = (targets) ->
      {"#{t}.#{user.id}", true for {t, user} in *targets}

    it "gets notification targets for topic in streak", ->
      user_1 = factory.Users!
      streak\join user_1

      targets = flatten_targets post\notification_targets!
      assert.same {
        -- streak owner
        ["topic.#{streak.user_id}"]: true
      }, targets

    it "gets notification targets for post in topic", ->
      subscriber = factory.Users!
      topic\subscribe subscriber

      new_post = factory.community.Posts topic_id: topic.id
      topic\increment_from_post new_post

      targets = flatten_targets new_post\notification_targets!

      assert.same {
        -- topic owner
        ["post.#{topic.user_id}"]: true
        ["post.#{subscriber.id}"]: true
      }, targets

    it "gets notification targets for topic in streak created by host", ->
      -- it should send to all participants
      user_1 = factory.Users!
      user_2 = factory.Users!
      user_3 = factory.Users!
      user_pending = factory.Users!

      streak\join user_1
      streak\join user_2
      pending = streak\join user_pending
      pending\update pending: true

      topic\update user_id: streak.user_id
      post\update user_id: streak.user_id
      post\refresh!

      targets = flatten_targets post\notification_targets!

      assert.same {
        -- streak owner not included, they made the post
        -- the participant
        ["topic.#{user_1.id}"]: true
        ["topic.#{user_2.id}"]: true
      }, targets



