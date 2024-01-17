import sanitize_html, convert_links from require "helpers.html"
import time_ago_in_words from require "lapis.util"
import to_json from require "lapis.util"

import login_and_return_url from require "helpers.app"

class CommunityPostList extends require "widgets.base"
  @needs: {
    "topic"
    "posts"
    "flair_by_user_id"
  }

  inner_content: =>
    for i, post in ipairs @posts
      @render_post post, {
        last: i == #@posts
        first: i == 1
        depth: 1
      }

  render_post: (post, opts) =>
    -- return if post.deleted and not (post.children and post.children[1])
    user = post\get_user!
    suspended = user\display_as_suspended @current_user

    data = { id: post.id, user_id: post.user_id }

    div {
      id: "post-#{post.id}"
      class: {
        "community_post"
        deleted: post.deleted
        is_reply: opts.depth > 1
        has_replies: post.children and post.children[1]
      }
      "data-post": to_json data
    }, ->
      if opts.first
        div id: "first-post"

      if opts.last
        div id: "last-post"


      div class: "post_content", ->
        div class: "post_header", ->
          if suspended or post.deleted
            div class: "avatar_container", ->
              div {
                class: "post_avatar"
                  -- streak club logo should go here
                style: "background-image: url(#{@asset_url "images/logo-144.png"})"
              }
          else
            a href: @url_for(user), class: "avatar_container", ->
              div {
                class: "post_avatar"
                style: "background-image: url(#{user\gravatar 80})"
              }

          div class: "post_header_content", ->
            span class: "post_author", ->
              if post.deleted
                em "Deleted"
              elseif suspended
                em "Suspended account"
              else
                a href: @url_for(user), user\name_for_display!

            if @streak and @streak\is_host user
              span class: "author_flag host", "Host"
            elseif user\is_admin!
              span class: "author_flag admin",
                user.community_user and user.community_user.flair or "Admin"

            elseif f = @flair_by_user_id and @flair_by_user_id[user.id]
              span class: "author_flag owner", f

            span class: "post_date", title: post.created_at, ->
              if post.deleted
                text time_ago_in_words post.created_at
              else
                a href: @url_for(post), time_ago_in_words post.created_at

            if post.edits_count > 0
              text " "
              span class: "edit_message",
                "(Edited #{@plural post.edits_count, "time", "times"})"
              text " "


        if post.deleted
          if @topic\allowed_to_moderate @current_user
            div class: "deleted_tools", ->
              a {
                class: "delete_post_btn post_action"
                href: @url_for "community.delete_post", { post_id: post.id }
                title: "Remove all evidence of this post"
                "Purge..."
              }

          em class: "deleted_message", "Deleted post"
        else
          div class: "post_body", ->
            if suspended
              p class: "suspended_message", ->
                em "This account has been suspended for violating our terms of service or spamming"
            else
              raw sanitize_html convert_links post.body

        div class: "post_footer", ->

          if post\is_topic_post! and not @topic.permanent
            a {
              class: "post_action"
              href: "#reply-thread"
            }, ->
              @icon "reply", 16
              text " "
              text "Reply"

          elseif post\allowed_to_reply @current_user
            a {
              class: "post_action"
              href: @url_for("community.reply_post", post_id: post.id)
            }, ->
              @icon "reply", 16
              text " "
              text "Reply"
          elseif not @current_user and not post.deleted
            a {
              class: "post_action"
              "data-register_action": "community_reply"
              href: login_and_return_url @, nil, "community"
            }, ->
              @icon "reply", 16
              text " "
              text "Reply"

          if post\allowed_to_edit @current_user
            a {
              class: "post_action"
              href: @url_for("community.edit_post", post_id: post.id)
              "Edit"
            }

            a {
              class: "delete_post_btn post_action"
              href: @url_for("community.delete_post", post_id: post.id)
              "Delete..."
            }

      if post.children and post.children[1]
        if opts.depth > 9
          div class: "view_more_replies", ->
            a href: @url_for(post), class: "button outline forward_link", "View more in thread"
        else
          div class: {
            "community_post_replies"
            top_level_replies: opts.depth == 1
          }, ->
            for child in *post.children
              @render_post child, depth: opts.depth + 1

