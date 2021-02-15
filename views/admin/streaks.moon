
import Streaks from require "models"

class AdminStreaks extends require "widgets.admin.page"
  @include "widgets.pagination_helpers"
  @include "widgets.table_helpers"

  @needs: {"streaks", "pager"}

  page_name: "streaks"

  column_content: =>
    h2 "Streaks"

    @render_pager @pager

    @column_table @streaks, {
      {"", (streak) ->
        a href: @admin_url_for(streak), "Admin"
      }
      "id"
      {"streak", (streak) ->
        a href: @url_for(streak), streak.title
      }
      {"user", (streak) ->
        user = streak\get_user!
        a href: @url_for(user), user\name_for_display!
        if user\is_suspended!
          strong " suspended"

        if user\is_spam!
          strong " spam"
      }

      {"rate", Streaks.rates}
      {"category", Streaks.categories}
      {"publish_status", Streaks.publish_statuses}
      {"late_submit_type", Streaks.late_submit_types}
      {"membership_type", Streaks.membership_types}

      "deleted"
      {"submissions_count", label: "submits"}
      {"users_count", labels: "joined"}
      {"pending_users_count", label: "pending joins"}
      "created_at"
    }
    @render_pager @pager


