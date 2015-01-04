import Streaks from require "models"

SubmissionList = require "widgets.submission_list"

class ViewStreakUnit extends require "widgets.base"
  @needs: {"streak", "submissions"}

  inner_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "admin_tools", ->
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"
        text " "
        a href: "", "Generate submit url"

    p ->
      a href: @url_for(@streak), "Return to streak"

    h2 @streak.title
    end_date = @streak\increment_date_by_unit date @unit_date
    h3 "Submissions from #{@unit_date\fmt Streaks.day_format_str} to #{end_date\fmt Streaks.day_format_str}"
    widget SubmissionList

