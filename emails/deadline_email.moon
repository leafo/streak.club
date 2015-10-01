import format_date from require "helpers.format"
import Streaks from require "models"

class DeadlineEmail extends require "emails.email"
  @needs: { "streak" }

  subject: => "Don't forget to submit to #{@streak.title}"

  body: =>
    h1 "Don't forget to submit to #{@streak.title}"

    p -> raw "Hello %recipient.name_for_display%,"
    p ->
      text "You signed up for "
      a href: @url_for(@streak), @streak.title
      current_unit_end = @streak\increment_date_by_unit @streak\current_unit!

      text ". The first submission is due in
      about #{format_date current_unit_end} (#{current_unit_end\fmt Streaks.timestamp_format_str} UTC)"

    p style: "text-align: center;", ->
      a {
        href: @url_for(@streak)
        style: "background-color: #34a0f2; border-radius: 8px; font-size: larger; color: white; text-decoration: none; font-weight: bold; padding: 8px 20px; display: inline-block;"
        "Submit"
      }


