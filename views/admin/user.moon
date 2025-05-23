import SpamScans from require "models"

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

      section ->
        text "Admin: "
        a {
          href: @url_for "admin.uploads", nil, user_id: @user.id
        }, "Uploads"
        text " "
        a {
          href: @url_for "admin.submissions", nil, user_id: @user.id
        }, "Submissions"
        text " "
        a {
          href: @url_for "admin.comments", nil, user_id: @user.id
        }, "Comments"

        text " "
        a {
          href: @url_for "admin.streaks", nil, user_id: @user.id
        }, "Streaks"

    div class: "admin_columns", ->
      @field_table @user, {
        "id"
        "username"
        "slug"
        "display_name"
        "email"
        "streaks_count"
        "submissions_count"
        "hidden_submissions_count"
        {"last_active", type: "date"}
        "last_seen_feed_at"
        ":is_admin"
        ":is_suspended"
        ":is_spam"

        "created_at"
        "updated_at",
      }
      

      section ->
        if rr = @user\get_register_captcha_result!
          strong "Recaptcha result"
          @field_table rr.data, {
            "hostname"
            "score"
          }

        if referrer = @user\get_register_referrer!
          strong "Register referrer"
          @field_table referrer, {
            "referrer"
            "landing"
            "user_agent"
            "accept_lang"
          }

    @render_update_forms!

    section ->
      h3 "Spam"

      p ->
        a {
          class: "button"
          href: @url_for "admin.spam_queue", nil, user_id: @user.id
        }, "Spam queue..."

      if scan = @user\get_spam_scan!
        br!
        @field_table scan, {
          {"score", (scan) ->
            if scan.score
              code title: scan.score, "%0.4f"\format scan.score
            else
              code class: "sub", "∅"
          }
          {"review_status", SpamScans.review_statuses}
          {"train_status", SpamScans.train_statuses}
          "created_at", "updated_at"
        }
      else
        p ->
          em "This user has no spam scan"

        form {
          method: "post"
          class: "form"
          action: @url_for "admin.spam_queue", nil, user_id: @user.id
        }, ->
          @csrf_input!
          button  {
            class: "button"
            name: "action"
            value: "refresh"
          }, "Refresh spam scan"


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

    h3 "Created streaks"
    @column_table @user\get_created_streaks!, {
      {"", (streak) ->
        a href: @admin_url_for(streak), "Admin"
      }
      "id"
      {"streak", (streak) ->
        a href: @url_for(streak), streak.title
      }
      {"submissions_count", label: "submits"}
      {"users_count", labels: "joined"}
      "deleted"
      "created_at"
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

