
import Users from require "models"

class AdminUsers extends require "widgets.admin.page"
  @include "widgets.pagination_helpers"
  @include "widgets.table_helpers"

  @needs: {"users", "pager"}

  column_content: =>
    h2 "Users"

    @render_pager @pager
    @column_table @users, {
      {"", (user) ->
        a href: @admin_url_for(user), "Admin"
      }
      "id"
      {"name", (user) ->
        a href: @url_for(user), user\name_for_display!
      }
      "streaks_count"
      "submissions_count"
      ":is_admin"
      ":is_suspended"
      ":is_spam"
      "created_at"
      {"last_active", type: "date"}
    }
    @render_pager @pager

