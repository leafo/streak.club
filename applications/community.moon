
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

  [topic: "/t/:topic_id(/:topic_slug)"]: respond_to {
    on_error: =>
      not_found

    before: =>
      TopicsFlow = require "community.flows.topics"
      TopicsFlow(@)\load_topic!

    GET: =>
      if @topic.slug != "" and @params.topic_slug != @topic.slug
        return redirect_to: @url_for @topic

      BrowsingFlow = require "community.flows.browsing"
      @flow = BrowsingFlow(@)

      per_page = 50

      @flow\topic_posts(:per_page)

      -- fix bad pagination
      if (@params.before or @params.after) and not next @posts
        return redirect_to: @url_for @topic

      render: true

    POST: =>
      assert_csrf @
      "ok"

  }

  [post: "/post/:post_id"]: =>
    "post"

  [edit_post: "/post/:post_id/edit"]: =>
    "edit post"

  [reply_post: "/post/:post_id/reply"]: =>
    "reply post"

  [new_post: "/topic/:topic_id/new-post"]: respond_to {
    on_error: =>
      not_found

    before: =>
      TopicsFlow = require "community.flows.topics"
      TopicsFlow(@)\load_topic!

    GET: =>
      BrowsingFlow = require "community.flows.browsing"

      post = @topic\get_topic_post!
      @parent_posts = {post}
      BrowsingFlow(@)\preload_posts @parent_posts

      render: true

    POST: =>
      assert_csrf @

      PostsFlow = require "community.flows.posts"
      PostsFlow(@)\new_post!

      -- @post\send_notifications!
      -- if @params.subscribe
      --   @topic\subscribe @current_user

      json: {
        redirect_to: @url_for(@topic\latest_post_url_params @) .. "#post-#{@post.id}"
      }
  }

  [delete_post: "/post/:post_id/delete"]: respond_to {
    POST: =>
      "delete"
  }

  [post_in_topic: "/post-in-topic/:post_id"]: =>
    "in topic..."



