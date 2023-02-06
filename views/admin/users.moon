
import Users from require "models"

import enum from require "lapis.db.model"

class AdminUsers extends require "widgets.admin.page"
  @include "widgets.pagination_helpers"
  @include "widgets.table_helpers"

  @needs: {"users", "pager"}

  page_name: "users"

  column_content: =>
    h2 "Users"

    @filter_form (field) ->
      field "id"
      field "user_token"
      field "exclude_token"
      field "spam_untrained", type: "boolean"
      field "active_7day", type: "boolean"
      field "has_submission", type: "boolean"

      fieldset ->
        legend "flags"
        field "admin", type: "boolean"
        field "suspended", type: "boolean"
        field "spam", type: "boolean"

      field "sort", enum {
        "submissions_count"
        "streaks_count"
      }

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
        a class: "spam_scan", href: @url_for("admin.spam_queue", nil, user_id: user.id), ->
          if scan = user\get_spam_scan!
            if scan\is_trained!
              import SpamScans from require "models"
              strong "data-status": SpamScans.train_statuses[scan.train_status], SpamScans.train_statuses[scan.train_status]
            else
              if scan.score
                code "%.2f"\format scan.score
              else
                code class: "sub", "∅"
          else
            raw "&bullet;"
      }
      {"streaks_count", label: "streaks"}
      {"submissions", (user) ->
        if user.submissions_count > 0
          a href: @url_for("admin.submissions", nil, user_id: user.id), @format_number user.submissions_count
        else
          span style: "color: gray", "0"
      }
      {"following_count", label: "following"}
      {"followers_count", label: "followers"}
      {":is_admin", label: "admin"}
      {":is_suspended", label: "suspended"}
      {":is_spam", label: "spam"}
      "created_at"
      {"last_active", type: "date"}
      {"ips", (user) ->
        ip_addresses = user\get_ip_addresses!
        limit = 15
        has_more = false

        for idx, ip in ipairs ip_addresses
          if idx > 1
            text ", "

          if idx > limit
            has_more = true
            break

          a href: @url_for("admin.users", nil, user_token: "ip.#{ip.ip}"), ->
            code ip.ip

        if has_more
          strong "#{#ip_addresses - limit} more"

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
          class: "button red"
          name: "action"
          value: "bulk_train_spam"
        }, "Bulk train spam"

        label ->
          input type: "checkbox", name: "confirm", required: true
          text " Confirm"



