import Streaks from require "models"

SubmissionList = require "widgets.submission_list"

date = require "date"

class ViewStreakUnit extends require "widgets.base"
  @needs: {"streak", "submissions"}

  inner_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "admin_tools", ->
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"
        raw " &middot; "
        a href: @url_for("streak_unit_submit_url", id: @streak.id, date: @params.date),
          "Generate submit url"

    p ->
      a href: @url_for(@streak), "Return to streak"

    div class: "page_header", ->
      h2 @streak.title
      end_date = @streak\increment_date_by_unit date @unit_date
      h3 "Submissions from #{@unit_date\fmt Streaks.day_format_str} to #{end_date\fmt Streaks.day_format_str}"

    if next @submissions
      widget SubmissionList
    else
      p class: "empty_message", "No submissions"

