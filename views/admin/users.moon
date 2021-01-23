
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
      {"id", type: "checkbox", form: "bulk_update", input: "user_ids"}
      {"", (user) ->
        a href: @admin_url_for(user), "Admin"
      }
      "id"
      {"name", (user) ->
        a href: @url_for(user), user\name_for_display!
      }
      "email"
      {"spam", (user) ->
        a href: @url_for("admin.spam_queue", nil, user_id: user.id), ->
          if scan = user\get_spam_scan!
            if scan\is_trained!
              import SpamScans from require "models"
              strong SpamScans.train_statuses[scan.train_status]
            else
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

    details class: "toggle_form", ->
      summary "Bulk update"

      form method: "post", id: "bulk_update", ->
        @csrf_input!

        button {
          class: "button"
          type: "button"
          onClick: "$('[name^=user_ids]').prop('checked', true)"
        }, "Select all..."

        text " "

        button {
          class: "button"
          name: "action"
          value: "bulk_train_spam"
        }, "Bulk train spam"

        label ->
          input type: "checkbox", name: "confirm", required: true
          text " Confirm"



