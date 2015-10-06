import format_date from require "helpers.format"
import Streaks from require "models"

class LateSubmitEmail extends require "emails.email"
  @needs: { "streak" }
  @include "emails.streak_helpers"

  subject: =>
    "You can still submit to #{@streak\interval_noun false} #{@streak\current_unit_number! - 1} of #{@streak.title}"

  body: =>
    missed_unit = @streak\current_unit_number! - 1
    error "invalid unit for late submit: #{missed_unit}" if missed_unit < 1

    unit_noun = @streak\interval_noun false

    h1 "You can late submit to #{@streak.title}"

    p -> raw "Hello %recipient.name_for_display%,"

    p ->
      text "You're signed up for "
      a href: @url_for(@streak), @streak.title
      text ". "
      
      text "but you missed the deadline for "
      if missed_unit == 1
        text "the first submission"
      else
        text "#{unit_noun} #{missed_unit}"
      
      text ". Not to worry, the host has enabled late submissions!
      Feel free to submit whenever you have the chance."

    p ->
      text "You can find the late submit link on the page of the #{unit_noun}
      you missed:"

    @big_button "Go to late submit", @url_for @streak\unit_url_params missed_unit
    @leave_streak_message!
