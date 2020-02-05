class AdminUser extends require "widgets.admin.page"
  @needs: {"user"}
  @include "widgets.form_helpers"
  @include "widgets.table_helpers"

  column_content: =>
    @content_for "all_js", ->
      @include_js "admin.js"

    div class: "page_header", ->
      h2 "Edit user"
      h3 ->
        a href: @url_for(@user), @user\name_for_display!

    @field_table @user, {
      "id", "created_at", "updated_at",
      "streaks_count"
      "submissions_count"
      "hidden_submissions_count"
      {"last_active", type: "date"}
      "last_seen_feed_at"
      ":is_admin"
      ":is_suspended"
      ":is_spam"
    }

    @render_update_forms!

    h3 "Joined streaks"
    @column_table @user\get_streak_users!, {
      {"streak", (su) ->
        streak = su\get_streak!
        a href: @url_for(streak), streak.title
      }
      "submissions_count"
      "current_streak"
      "longest_streak"
      "last_submitted_at"
      "created_at"
      "pending"
    }

  render_update_forms: =>
    details class: "toggle_form", ->
      summary "Update Flags"
      form class: "form", method: "post", ->
        @csrf_input!

        div class: "input_row", ->
          div class: "label", "Flags"

          @checkboxes {
            {"suspended", "suspended"}
            {"spam", "spam"}
          }, {
            suspended: @user\is_suspended!
            spam: @user\is_spam!
          }

        button class: "button", name: "action", value: "update_flags", "Update flags"

        text " "
        label ->
          input type: "checkbox", name: "confirm", required: true
          text " confirm"


    details class: "toggle_form", ->
      summary "Set password"
      form class: "form", method: "post", ->
        @csrf_input!
        @text_input_row {
          label: "Password"
          name: "password"
        }

        button class: "button", name: "action", value: "set_password", "Set password"

        text " "
        label ->
          input type: "checkbox", name: "confirm", required: true
          text " confirm"


