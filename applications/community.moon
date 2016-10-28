
lapis = require "lapis"

import
  respond_to
  capture_errors
  capture_errors_json
  assert_error
  from require "lapis.application"

import require_login from require "helpers.app"
import assert_csrf from require "helpers.csrf"

class CommunityApplication extends lapis.Application
  @name: "community."

  [streak: "/s/:id/:slug/discussion"]: capture_errors {
    on_error: =>
      not_found

    =>
      @flow("streak")\load_streak!

      unless @streak.community_category_id
        @streak\create_default_category!
        @streak\refresh!

      @category = @streak\get_community_category!
      @flow("community")\show_category!
      render: true
  }

  [new_topic: "/category/:category_id/new-topic"]: require_login respond_to {
    on_error: => not_found

    before: =>
      CategoriesFlow = require "community.flows.categories"
      CategoriesFlow(@)\load_category!
      assert_error @category\allowed_to_post_topic(@current_user), "not allowed to post"
      @title = "New topic"

    GET: =>
      render: true

    POST: =>
      assert_csrf @

      TopicsFlow = require "community.flows.topics"
      TopicsFlow(@)\new_topic!
      -- @post\send_notifications!

      json: {
        redirect_to: @url_for @topic
      }

  }

  [topic: "/t/:topic_id(/:topic_slug)"]: =>
    "topic"

  [post: "/post/:post_id"]: =>
    "post"

  [post_in_topic: "/post-in-topic/:post_id"]: =>
    "in topic..."



