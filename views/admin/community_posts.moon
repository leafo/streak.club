class AdminCommunityPosts extends require "widgets.admin.page"
  @needs: {"posts"}

  @include "widgets.table_helpers"
  @include "widgets.pagination_helpers"

  column_content: =>
    h2 "Community posts"
    @render_pager @pager

    @column_table @posts, {
      {"created_at", (post) ->
        span title: post.created_at, @relative_timestamp post.created_at
      }

      {"streak", (post) ->
        topic = post\get_topic!
        category = topic and topic\get_category!
        if streak = category and category\get_streak!
          a href: @url_for(streak), streak.title
      }

      {"topic", (post) ->
        if topic = post\get_topic!
          a href: @url_for(topic), topic\name_for_display!
      }

      {"user", (post) ->
        if user = post\get_user!
          a href: @url_for(user), user\name_for_display!
      }
      {"text", (post) ->
        text @truncate post\extract_text!, 80
      }
    }

    @render_pager @pager
