
lapis = require "lapis"

import
  respond_to
  capture_errors
  capture_errors_json
  assert_error
  from require "lapis.application"

import require_login from require "helpers.app"
import assert_csrf from require "helpers.csrf"
import assert_valid from require "lapis.validate"

import not_found from require "helpers.app"

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

      @title = "Discussion | #{@streak.title}"

      @category = @streak\get_community_category!
      @flow("community")\show_category!
      render: true
  }

  [new_topic: "/category/:category_id/new-topic"]: require_login respond_to {
    on_error: => not_found

    before: =>
      CategoriesFlow = require "community.flows.categories"
      CategoriesFlow(@)\load_category!
      assert_error @category\allowed_to_post_topic(@current_user, @), "not allowed to post"
      @title = "New topic"
      @streak = @category\get_streak!
      assert_error @streak\allowed_to_view(@current_user), "invalid streak"

    GET: =>
      render: true

    POST: capture_errors_json =>
      assert_csrf @

      TopicsFlow = require "community.flows.topics"
      TopicsFlow(@)\new_topic!
      @post\send_notifications!

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


      @category = @topic\get_category!
      @streak = @category\get_streak!

      @title = "#{@topic\name_for_display!} by #{@topic\get_user!\name_for_display!} | #{@streak.title}"

      assert_error @streak\allowed_to_view(@current_user), "invalid streak"

    GET: =>
      if @topic.slug != "" and @params.topic_slug != @topic.slug
        return redirect_to: @url_for @topic

      BrowsingFlow = require "community.flows.browsing"
      flow = BrowsingFlow(@)

      per_page = 50

      flow\topic_posts(:per_page)

      -- fix bad pagination
      if (@params.before or @params.after) and not next @posts
        return redirect_to: @url_for @topic

      render: true
  }

  [post: "/post/:post_id"]: capture_errors {
    on_error: => not_found

    =>
      BrowsingFlow = require "community.flows.browsing"
      BrowsingFlow(@)\post_single!

      @title = "Post by #{@post\get_user!\name_for_display!} in #{@topic\name_for_display!}"
      import extract_text from require "web_sanitize"
      @meta_description = extract_text(@post.body)\sub 1, 200

      -- -- TODO this should be aware of community_post notification objects and
      -- -- clear that out
      -- import Notifications from require "models"
      -- Notifications\clear_notifications_for_object_view { @post }, @current_user, {
      --   "community_reply"
      -- }

      render: true
  }


  [edit_post: "/post/:post_id/edit"]: respond_to {
    on_error: => not_found

    before: =>
      @editing = true

      PostsFlow = require "community.flows.posts"
      @flow = PostsFlow @
      @flow\load_post!

      @topic = @post\get_topic!

      assert_error @post\allowed_to_edit(@current_user), "invalid post"
      @title = "Edit post"


    GET: =>
      render: true

    POST: =>
      @flow\edit_post!

      json: {
        redirect_to: @url_for @post\in_topic_url_params @
      }
  }

  [reply_post: "/post/:post_id/reply"]: respond_to {
    on_error: => not_found

    before: =>
      PostsFlow = require "community.flows.posts"
      BrowsingFlow = require "community.flows.browsing"

      @flow = PostsFlow @
      @flow\load_post!
      @topic = @post\get_topic!

      ancestors = @post\get_ancestors!
      @parent_post = @post
      @parent_posts = {@post, unpack ancestors}
      BrowsingFlow(@)\preload_posts @parent_posts

      -- the parent post is not the current post
      @post = nil

      assert_error @parent_post\allowed_to_reply(@current_user, @), "invalid post"
      @title = "Reply to post"

    GET: =>
      render: true

    POST: capture_errors_json =>
      @flow\new_post!
      @post\send_notifications!

      @session.flash = "Your reply has been posted"

      json: {
        redirect_to: @url_for(@post\in_topic_url_params @)
      }
  }

  [new_post: "/topic/:topic_id/new-post"]: respond_to {
    on_error: =>
      not_found

    before: =>
      TopicsFlow = require "community.flows.topics"
      TopicsFlow(@)\load_topic!
      assert_error @topic\allowed_to_post(@current_user, @), "not allowed to post"

      @category = @topic\get_category!
      @streak = @category\get_streak!

    GET: =>
      BrowsingFlow = require "community.flows.browsing"

      post = @topic\get_topic_post!
      @parent_posts = {post}
      BrowsingFlow(@)\preload_posts @parent_posts

      render: true

    POST: capture_errors_json =>
      assert_csrf @

      PostsFlow = require "community.flows.posts"
      PostsFlow(@)\new_post!

      if @params.subscribe
        @topic\subscribe @current_user

      @post\send_notifications!

      json: {
        redirect_to: @url_for(@topic\latest_post_url_params @) .. "#post-#{@post.id}"
      }
  }

  [delete_post: "/post/:post_id/delete"]: respond_to {
    on_error: => not_found

    before: =>
      PostsFlow = require "community.flows.posts"
      @flow = PostsFlow @
      @flow\load_post!

      @topic = @post\get_topic!
      assert_error @post\allowed_to_edit(@current_user, "delete"),
        "invalid post (not allowed to edit)"

      BrowsingFlow = require "community.flows.browsing"
      BrowsingFlow(@)\post_single!

      @post.children = nil -- don't show children

      if @post\is_topic_post!
        @noun = "topic"
      else
        @noun = "post"

      @title = "Delete #{@noun} by #{@post\get_user!\name_for_display!} in #{@topic\name_for_display!}"

    GET: =>
      render: true

    POST: capture_errors_json =>
      assert_csrf @
      assert_valid @params, {
        {"action", one_of: {"delete"}}
      }

      @flow\delete_post!
      @session.flash = "Deleted #{@noun}"

      target = if @post\is_topic_post!
        @post\get_topic!\get_category!
      else
        @post\get_topic!

      json: {
        success: true
        redirect_to: @url_for target
      }

  }

  [post_in_topic: "/post/:post_id/view-in-topic"]: capture_errors {
    on_error: => not_found
    =>
      PostsFlow = require "community.flows.posts"
      @post = PostsFlow(@)\load_post!
      assert_error @post\allowed_to_view @current_user
      redirect_to: @url_for @post\in_topic_url_params @
  }

