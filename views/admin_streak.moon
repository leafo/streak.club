
import Streaks from require "models"

class AdminStreak extends require "widgets.page"
  @needs: {"streak"}

  @include "widgets.table_helpers"

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
      {"", -> a href: @url_for("admin_user", id: @streak\get_user!.id), "Admin"}
    }

    h3 "Tools"
    fieldset ->
      a {
        class: "button"
        href: @url_for("admin_email_streak", streak_id: @streak.id)
        "Email users..."
      }
      for email in *{"deadline", "late_submit"}
        br!
        br!
        form method: "post", action: @url_for("admin_send_streak_email", streak_id: @streak.id), ->
          @csrf_input!
          input type: "hidden", name: "email", value: email

          button class: "button", ->
            text "Send "
            code email
            text " email"

          text " "
          a href: @url_for("admin_send_streak_email", { streak_id: @streak.id }, :email),
            "preview recipients"

