
import Streaks from require "models"

class AdminStreak extends require "widgets.admin.page"
  @needs: {"streak"}

  @include "widgets.table_helpers"
  @include "widgets.form_helpers"

  column_content: =>
    div class: "page_header", ->
      h2 @streak.title
      h3 ->
        a href: @url_for(@streak), "View streak"
        raw " &middot; "
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"

    h3 "Streak"

    @field_table @streak, {
      "id", "title", "created_at", "updated_at",
      "end_date", "start_date", {"rate", Streaks.rates},
      "hour_offset",
      "short_description",
      "published", "deleted",
      "users_count",
      "submissions_count",
      {"category", Streaks.categories},
      {"publish_status", Streaks.publish_statuses},
      {"late_submit_type", Streaks.late_submit_types}
      {"membership_type", Streaks.membership_types}

      "last_deadline_email_at"
      "twitter_hash"
    }

    h3 "Owner"

    @field_table @streak\get_user!, {
      "id"
      "username"
      {"display name", -> text @streak\get_user!\name_for_display! }
      {"", -> a href: @url_for(@streak\get_user!), "Profile"}
      {"", -> a href: @admin_url_for(@streak\get_user!), "Admin"}
    }

    h3 "Related streaks"

    for list in *{@related, @other_related}
      import RelatedStreaks from require "models"
      continue unless next list
      @column_table list, {
        {"streak", (rs) ->
          if rs.streak_id == @streak.id
            em class: "sub", "current"
          else
            a href: @url_for(rs\get_streak!),
              @truncate rs\get_streak!.title
        }

        {"other_streak", (rs) ->
          if rs.other_streak_id == @streak.id
            em class:"sub", "current"
          else
            a href: @url_for(rs\get_other_streak!),
              @truncate rs\get_other_streak!.title
        }

        {"type", RelatedStreaks.types}
        "created_at"

        {"remove", (rs) ->
          form method: "post", ->
            @csrf_input!
            input type: "hidden", name: "related_streak_id", value: rs.id
            button name: "action", value: "remove_related", "remove"
        }
      }

    fieldset ->
      legend "Add related streak"
      form method: "post", class: "form", ->
        @csrf_input!

        @input_row "Type", ->
          @radio_buttons "related[type]", {
            {"related", "Related"}
            {"substreak", "Substreak"}
          }

        @text_input_row {
          label: "Other streak id"
          name: "related[streak_id]"
          required: true
        }

        @text_input_row {
          label: "Reason"
          name: "related[reason]"
        }

        div class: "button_row", ->
          button class: "button", name: "action", value: "add_related", "Submit"

    h3 "Tools"
    fieldset ->
      a {
        class: "button"
        href: @url_for("admin.email_streak", streak_id: @streak.id)
        "Email users..."
      }
      for email in *{"deadline", "late_submit"}
        br!
        br!
        form method: "post", action: @url_for("admin.send_streak_email", streak_id: @streak.id), ->
          @csrf_input!
          input type: "hidden", name: "email", value: email

          button class: "button", ->
            text "Send "
            code email
            text " email"

          text " "
          a href: @url_for("admin.send_streak_email", { streak_id: @streak.id }, :email),
            "preview recipients"

