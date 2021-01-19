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

    @render_update_forms!

    section ->
      h3 "Spam"

      scan = @user\get_spam_scan!

      if scan
        @field_table scan, {
          "score"
          {"review_status", SpamScans.review_statuses}
          {"train_status", SpamScans.train_statuses}
          "created_at", "updated_at"
        }
      else
        p ->
          em "This user has no spam scan"

      if scan and scan\needs_review!
        form method: "post", class: "form", ->
          @csrf_input!
          input type: "hidden", name: "action", value: "dismiss_spam_scan"
          button  {
            class: "button"
          }, "Dismiss scan"

      unless scan and scan\is_trained!
        form method: "post", class: "form", ->
          @csrf_input!
          input type: "hidden", name: "action", value: "refresh_spam_scan"
          button  {
            class: "button"
          }, "Refresh spam scan"


      if not scan or not scan\is_trained!
        form method: "post", class: "form", ->
          @csrf_input!
          input type: "hidden", name: "action", value: "train_spam_scan"
          fieldset ->
            legend "Train spam"

            button {
              name: "train"
              class: "button green"
              value: "ham"
            }, "Ham"
            text " "

            label ->
              input type: "checkbox", name: "confirm", required: true
              text " Confirm"

            text " "

            button {
              name: "train"
              class: "button red"
              value: "spam"
            }, "Spam"

      fieldset ->
        legend "Spam tokens"

        details class: "toggle_form", ->
          summary "Texts"
          texts = SpamScans\user_texts @user
          @column_table [{:text} for text in *texts], {
            "text"
          }

        details class: "toggle_form", ->
          summary "User tokens"

          tokens = SpamScans\tokenize_user @user
          @column_table [{:token} for token in *tokens], {
            "token"
          }


        details class: "toggle_form", ->
          summary "Text tokens"

          tokens = SpamScans\tokenize_user_text @user
          @column_table [{:token} for token in *tokens], {
            "token"
          }

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


