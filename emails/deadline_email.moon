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
      text ". "

      unit_number = @streak\current_unit_number!
      current_unit_end = @streak\current_unit_end_date!

      if unit_number == 1
        text "The first "
      else
        text "The next "

      text " submission is due in about #{format_date current_unit_end} (#{current_unit_end\fmt Streaks.timestamp_format_str} UTC)."

    p style: "text-align: center;", ->
      a {
        href: @url_for(@streak)
        style: "background-color: #34a0f2; border-radius: 8px; font-size: larger; color: white; text-decoration: none; font-weight: bold; padding: 8px 20px; display: inline-block;"
        "Go to Streak to Submit"
      }

    p style: "font-size: small; color: #666", ->
      text "If you want to leave the streak you can find the 'leave streak' button on the "
      a style: "color: #666", href: @url_for(@streak), "streak's page"
      text "."
