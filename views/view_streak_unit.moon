import Streaks from require "models"

StreakHeader = require "widgets.streak_header"
SubmissionList = require "widgets.submission_list"

date = require "date"

class ViewStreakUnit extends require "widgets.base"
  @needs: {"streak", "submissions"}


  js_init: =>
    "new S.ViewStreakUnit(#{@widget_selector!});"

  inner_content: =>
    widget StreakHeader {
      owner_tools_extra: =>
        raw " &middot; "
        a href: @url_for("streak_unit_submit_url", id: @streak.id, date: @params.date),
          "Generate submit url"
    }

    end_date = @streak\increment_date_by_unit date @unit_date
    h3 "Submissions from #{@unit_date\fmt Streaks.day_format_str} to #{end_date\fmt Streaks.day_format_str}"

    if next @submissions
      widget SubmissionList
    else
      p class: "empty_message", "No submissions"

