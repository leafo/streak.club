import Streaks from require "models"

StreakHeader = require "widgets.streak_header"
SubmissionList = require "widgets.submission_list"

date = require "date"

class ViewStreakUnit extends require "widgets.page"
  @needs: {"streak", "submissions"}

  responsive: true

  js_init: =>
    "new S.ViewStreakUnit(#{@widget_selector!});"

  inner_content: =>
    widget StreakHeader

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "owner_tools", ->
        a href: @url_for("streak_unit_submit_url", id: @streak.id, date: @params.date),
          "Generate late submit URL for participant"

    h3 class: "submission_list_title", ->
      text "Submissions from #{@start_time\fmt Streaks.day_format_str} to #{@end_time\fmt Streaks.day_format_str}"
      text " "
      span class: "sub", "(#{@pager\total_items!} total)"

    if @can_late_submit!
      div class: "late_submitter", ->
        p ->
          text "This submission time as ended but you can "
          a href: @streak_user\submit_url(@, @params.date), "late submit"
          text "."

    if next @submissions
      widget SubmissionList
    else
      p class: "empty_message", "No submissions"


  can_late_submit: =>
    return false unless @streak_user
    return false if @streak_submission
    return false unless @streak\can_late_submit @current_user
    date(true) > @end_time
