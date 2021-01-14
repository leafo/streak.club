
import Users from require "models"

import ip_to_asnum from require "helpers.geo"

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
      {"spam", (user) ->
        if scan = user\get_spam_scan!
          if scan.score
            code "%.2f"\format scan.score
          else
            code class: "sub", "∅"
        else
          raw "&bullet;"


      }
      {"streaks_count", label: "streaks"}
      {"submissions_count", label: "submissions"}
      {":is_admin", label: "admin"}
      {":is_suspended", label: "suspended"}
      {":is_spam", label: "spam"}
      "created_at"
      {"last_active", type: "date"}
      {"ips", (user) ->
        for idx, ip in ipairs user\get_ip_addresses!
          if idx > 1
            text ", "
          code ip.ip
      }
    }
    @render_pager @pager

