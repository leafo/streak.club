
import Streaks from require "models"

class AdminStreak extends require "widgets.base"
  @include "widgets.pagination_helpers"
  @needs: {"streaks", "pager"}

  inner_content: =>
    h2 "Streaks"

    @render_pager @pager
    element "table", class: "nice_table", ->
      thead ->
        tr ->
          td ""
          td "ID"
          td "Streak"
          td "Host"
          td "Rate"
          td "Category"
          td "Publish"
          td "Late submit"
          td "Membership"
          td "Deleted"

          td "Submits"
          td "Joined"

      for streak in *@streaks
        tr ->
          td ->
            a href: @url_for("admin_streak", id: streak.id), "Admin"

          td streak.id

          td ->
            a href: @url_for(streak), streak.title

          td ->
            a href: @url_for(streak\get_user!), streak\get_user!\name_for_display!

          td Streaks.rates[streak.rate]
          td Streaks.categories[streak.category]
          td Streaks.publish_statuses[streak.publish_status]
          td Streaks.late_submit_types[streak.late_submit_type]
          td Streaks.membership_types[streak.membership_type]

          td ->
            if streak.deleted
              text "Yes"

          td streak.submissions_count

          td ->
            text streak.users_count
            if streak.pending_users_count > 0
              text " (#{streak.pending_users_count})"


    @render_pager @pager


