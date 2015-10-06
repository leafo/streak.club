import format_date from require "helpers.format"
import Streaks from require "models"

class DeadlineEmail extends require "emails.email"
  @needs: { "streak" }
  @include "emails.streak_helpers"

  subject: => "Don't forget to submit to #{@streak.title}"

  body: =>
    h1 @subject!

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

    @big_button "Go to Streak to Submit", @url_for(@streak)
    @leave_streak_message!

