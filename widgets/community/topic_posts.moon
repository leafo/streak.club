import is_empty_html, sanitize_html from require "helpers.html"
import to_json from require "lapis.util"
import login_and_return_url from require "helpers.app"

PostList = require "widgets.community.post_list"
PostForm = require "widgets.community.post_form"

config = require("lapis.config").get!

class CommunityTopicPosts extends require "widgets.base"
  @include "widgets.community.topic_helpers"

  @needs: {
    "topic"
    "posts"

    "next_page"
    "prev_page"
  }

  noun: "posts"
  header_opts: nil

  js_init: =>
    -- "new I.CommunityViewTopic(#{@widget_selector!}, #{to_json data})"

  widget_classes: =>
    classes = super!
    classes ..= " locked" if @topic.locked
    classes

  inner_content: =>
    widget PostList!

    @topic_posts_pager "bottom_pager"
    @topic_reply_footer!

  topic_reply_footer: =>
    can_reply = @topic\allowed_to_post @current_user
    return unless @topic.locked or can_reply or not @current_user

    div class: "topic_posts_footer", ->
      if @topic.locked
        div class: "lock_message", ->
          @topic_lock_message!
      else
        if can_reply
          h2 "Reply"
          widget PostForm show_author: true
        elseif not @current_user
          div class: "create_account_banner", ->
            a {
              class: "button"
              "data-register_action": "community_reply"
              href: login_and_return_url(@, nil, "community")
            }, "Log in to reply"

            text "Log in to your streak.club account to participate."
