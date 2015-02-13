
import Streaks from require "models"

class AdminStreak extends require "widgets.base"
  @needs: {"streak"}

  @include "widgets.table_helpers"

  inner_content: =>
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

