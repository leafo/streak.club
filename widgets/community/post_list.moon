import sanitize_html from require "helpers.html"
import time_ago_in_words from require "lapis.util"
import to_json from require "lapis.util"

import login_and_return_url from require "helpers.app"

class CommunityPostList extends require "widgets.base"
  @needs: {
    "topic"
    "posts"
    "flair_by_user_id"
  }

  sidebar_avatar: true
  hide_voting: false

  inner_content: =>
    for i, post in ipairs @posts
      @render_post post, {
        last: i == #@posts
        first: i == 1
        depth: 1
      }

  render_post: (post, opts) =>
    return if post.deleted and not (post.children and post.children[1])
    user = post\get_user!

    sidebar_avatar = not post.deleted and @sidebar_avatar and opts.depth == 1

    data = { id: post.id, user_id: post.user_id }

    if opts.first
      div id: "first-post"

    if opts.last
      div id: "last-post"

    div {
      id: "post-#{post.id}"
      class: {
        "community_post"
        deleted: post.deleted
        is_reply: opts.depth > 1
        has_replies: post.children and post.children[1]
        sidebar_avatar: sidebar_avatar
        last_root_post: not (post.children and post.children[1]) and opts.depth == 1 and opts.last
      }
      "data-post": to_json data
    }, ->
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
        return

      div class: "post_content", ->
        div class: "post_header", ->
          a href: @url_for(user), class: "avatar_container", ->
            div {
              class: "post_avatar"
              style: "background-image: url(#{user\gravatar 80})"
            }

          div class: "post_header_content", ->
            span class: "post_author", ->
              a href: @url_for(user), user\name_for_display!

            if user\is_admin!
              span class: "author_flag admin",
                user.community_user and user.community_user.flair or "Admin"
            elseif f = @flair_by_user_id and @flair_by_user_id[user.id]
              span class: "author_flag owner", f

            span class: "post_date", title: post.created_at, ->
              a href: @url_for(post), time_ago_in_words post.created_at

            if post.edits_count > 0
              text " "
              span class: "edit_message",
                "(Edited #{@plural post.edits_count, "time", "times"})"
              text " "

        div class: "post_body", ->
          raw sanitize_html post.body

        div class: "post_footer", ->
          if post\allowed_to_edit @current_user
            a {
              class: "post_action"
              href: @url_for("community.edit_post", post_id: post.id)
              "Edit"
            }

            a {
              class: "delete_post_btn post_action"
              href: @url_for("community.delete_post", post_id: post.id)
              "Delete"
            }

          if (not post\is_topic_post! or @topic.permanent) and post\allowed_to_reply @current_user
            a {
              class: "post_action"
              href: @url_for("community.reply_post", post_id: post.id)
              "Reply"
            }
          elseif not @current_user
            a {
              class: "post_action"
              "data-register_action": "community_reply"
              href: login_and_return_url @, nil, "community"
              "Reply"
            }

    if post.children and post.children[1]
      if opts.depth > 9
        div class: "view_more_replies", ->
          a href: @url_for(post), class: "button outline forward_link", "View more in thread"
      else
        div class: {
          "community_post_replies"
          top_level_replies: opts.depth == 1
          last_root_post: opts.depth == 1 and opts.last
        }, ->
          for child in *post.children
            @render_post child, depth: opts.depth + 1

