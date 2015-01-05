
date = require "date"

class StreakUnits extends require "widgets.base"
  @needs: {"streak", "completed_units", "unit_counts"}

  base_widget: false
  inner_content: =>
    day_str = "%Y-%m-%d"
    today = date date(true)\getdate!

    formatted_today = today\fmt day_str

    start_date = date @streak.start_date
    end_date = date @streak.end_date

    assert start_date < end_date

    current_date = date start_date

    while current_date < end_date
      formatted_date = current_date\fmt day_str
      submission_id = @completed_units and @completed_units[formatted_date]
      count = @unit_counts and @unit_counts[formatted_date] or 0

      current_time = date(current_date)\addhours @streak.hour_offset

      classes = "streak_unit"
      classes ..= " before_today" if current_time < today
      classes ..= " today" if formatted_date == formatted_today
      classes ..= " submitted" if submission_id

      pretty_date = @streak\format_date_unit current_date

      tooltip = if today < current_time
        pretty_date
      else
        "#{pretty_date}: #{@plural count, "submission", "submissions"}"

      if submission_id
        tooltip ..= " - You submitted"

      a href: @url_for("view_streak_unit", date: formatted_date, id: @streak.id), ->
        div {
          class: classes
          "data-date": tostring current_date
          "data-tooltip": tooltip
        }

      @streak\increment_date_by_unit current_date


