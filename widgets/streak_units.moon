date = require "date"

import Streaks from require "models"

class StreakUnits extends require "widgets.base"
  @needs: {"streak", "completed_units", "unit_counts"}

  user_id: nil

  inner_content: =>
    if @streak\has_end!
      @render_all_units!
    else
      @render_recent_units!

  render_recent_units: (count=154) =>
    start_date = @streak\start_datetime!
    current_date = date true
    today_unit = @streak\truncate_date date true

    cutoff_date = @start_date and date @start_date

    highlight_unit = if @highlight_date
      @streak\truncate_date(@highlight_date)
    else
      today_unit

    while count > 0 and start_date < current_date
      break if current_date < cutoff_date

      unit_date = @streak\truncate_date current_date
      formatted_date = unit_date\fmt Streaks.day_format_str
      submission_id = @completed_units and @completed_units[formatted_date]
      unit_count = @unit_counts and @unit_counts[formatted_date] or 0

      show_count = false

      classes = "streak_unit"
      classes ..= " submitted" if submission_id

      before_unit = unit_date < today_unit
      if before_unit
        classes ..= " before_current_unit"
        show_count = true

      delta = date.diff(highlight_unit, unit_date)\spandays!
      if delta == 0
        classes ..= " current_unit"
        show_count = true

      unit_url = @url_for "view_streak_unit", {
        date: formatted_date
        id: @streak.id
      }, submission_id and @user_id and {user_id: @user_id} or nil

      pretty_date = @streak\format_date_unit unit_date

      tooltip = if not show_count or not @unit_counts
        pretty_date
      else
        "#{pretty_date}: #{@plural unit_count, "submission", "submissions"}"

      if submission_id
        tooltip ..= " - Submitted"

      a href: unit_url, ->
        div {
          class: classes
          "data-date": tostring current_date
          "data-tooltip": tooltip
          @unit_counts and show_count and tostring(unit_count) or nil
        }


      count -= 1
      @streak\increment_date_by_unit current_date, -1


  render_all_units: =>
    today = date true
    today_unit = @streak\truncate_date today

    highlight_unit = if @highlight_date
      @streak\truncate_date(@highlight_date)
    else
      today_unit

    -- IN STREAK LOCAL TIME!
    start_date = date @streak.start_date
    end_date = date @streak.end_date

    assert start_date < end_date

    current_date = date start_date

    while current_date < end_date
      formatted_date = current_date\fmt Streaks.day_format_str
      submission_id = @completed_units and @completed_units[formatted_date]
      count = @unit_counts and @unit_counts[formatted_date] or 0

      current_time = date(current_date)\addhours -@streak.hour_offset

      classes = "streak_unit"
      show_count = false
      before_unit = current_time < today_unit
      if before_unit
        classes ..= " before_current_unit"
        show_count = true

      delta = date.diff(highlight_unit, current_time)\spandays!
      if delta == 0
        classes ..= " current_unit"
        show_count = true

      classes ..= " submitted" if submission_id

      pretty_date = @streak\format_date_unit current_date

      tooltip = if not show_count or not @unit_counts
        pretty_date
      else
        "#{pretty_date}: #{@plural count, "submission", "submissions"}"

      if submission_id
        tooltip ..= " - Submitted"

      unit_url = @url_for "view_streak_unit", {
        date: formatted_date
        id: @streak.id
      }, submission_id and @user_id and {user_id: @user_id} or nil

      a href: unit_url, ->
        div {
          class: classes
          "data-date": tostring current_date
          "data-tooltip": tooltip
          @unit_counts and show_count and tostring(count) or nil
        }

      @streak\increment_date_by_unit current_date

