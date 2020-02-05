
import to_json from require "lapis.util"
import time_ago_in_words from require "lapis.util"

class CommunityTopicList extends require "widgets.base"
  @needs: {
    "category"
    "topics"
  }

  js_init: =>

  inner_content: =>
    section class: "topic_table", ->
      div class: "topic_table_header", ->
        div "Topic"
        div class: "last_post_header", "Last post"

      div class: "topic_table_body", ->
        @render_topics!

  render_topics: =>
    moderator = @category and @category\allowed_to_moderate @current_user

    for topic in *@topics
      has_unread = topic\has_unread @current_user
      row_classes = "topic_row"

      if has_unread
        row_classes ..= " unread_posts"

      row_opts = {
        class: row_classes
        "data-topic_id": topic.id
      }

      div row_opts, ->
        div class: "topic_main", ->
          div class: "topic_title", ->
            if topic.sticky
              span class: "topic_tag sticky_flag", "Sticky"

            if topic.locked
              span class: "topic_tag lock_flag", "Locked"

            if has_unread
              span class: "topic_tag new_flag", "New"

            a {
              href: @url_for(topic),
              class: "topic_link"
            }, @truncate topic\name_for_display!, 80

          div class: "topic_poster", ->
            user = topic\get_user!
            text "started by "
            if user\display_as_suspended @current_user
              em class: "topic_author", "Suspended account"
            else
              a class: "topic_author", href: @url_for(user), user\name_for_display!

            text " "
            span class: "topic_date", title: topic.created_at, ->
              text time_ago_in_words topic.created_at

            unless topic\is_single_page!
              text " "
              a {
                class: "last_page_link"
                href: @url_for(topic\last_page_url_params @) .. "#last-post"
              }, "Last page →"

        div class: "topic_stats", ->
          div ->
            span class: "number_value", @number_format topic.posts_count
            text " "
            if topic.posts_count == 1
              text "post"
            else
              text "posts"


          div ->
            span class: "number_value", @number_format topic.views_count
            text " "
            if topic.views_count == 1
              text "view"
            else
              text "views"

        div class: "topic_last_post", ->
          last_post = topic.last_post
          unless last_post
            div class: "no_last_post", "No posts yet"
            return

          user = last_post\get_user!
          suspended = user\display_as_suspended @current_user

          if suspended
            div class: "avatar_container", ->
              av_url = user\gravatar 25, true
              div {
                class: "last_post_avatar"
                style: "background-image: url(#{av_url})"
              }
          else
            a href: @url_for(user), class: "avatar_container", ->
              av_url = user\gravatar 25
              div {
                class: "last_post_avatar"
                style: "background-image: url(#{av_url})"
              }

          div class: "last_poster_group", ->
            div class: "last_post_author", ->
              if suspended
                em "Suspended account"
              else
                a href: @url_for(user), user\name_for_display!

            div class: "last_post_date", ->
              import format_date from require "helpers.datetime"
              abs, rel = format_date last_post.created_at
              a {
                rel: "nofollow"
                href: @url_for("community.post_in_topic", post_id: last_post.id)
                title: abs
              }, rel

