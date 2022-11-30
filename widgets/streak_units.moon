date = require "date"

import Streaks from require "models"

types = require "helpers.prop_types"
import render_prop from types

class StreakUnits extends require "widgets.base"
  @prop_types: {
    streak: render_prop types.instance_of Streaks
    completed_units: render_prop types.table + types.nil / -> {}
    unit_counts: render_prop types.table + types.nil

    hide_empty: types.nil / true + types.boolean
    user_id: types.number\is_optional!
    start_date: types.date\is_optional!

    highlight_date: types.date\is_optional!

    -- an iterator to provide list of unites for rendering
    unit_iterator: types.function\is_optional!
  }

  inner_content: =>
    if @props.unit_iterator
      @render_grouped @props.unit_iterator
    elseif @props.streak\has_end!
      div class: "unit_group_units", ->
        @render_units @all_units!
    else
      @render_grouped @recent_units!

  get_highlight_date: =>
    {:streak} = @props

    if @props.highlight_date
      streak\truncate_date @props.highlight_date
    else
      streak\truncate_date(date(true))\addhours streak.hour_offset

  all_units: =>
    {:streak} = @props

    start_date = streak\start_datetime!
    end_date = streak\end_datetime!

    assert start_date < end_date
    current_date = start_date\copy!

    coroutine.wrap ->
      while current_date < end_date
        coroutine.yield current_date\copy!
        streak\increment_date_by_unit current_date

  recent_units: =>
    {:streak} = @props

    is_daily = streak.rate == Streaks.rates.daily

    y, m = date(true)\getdate!

    local bottom
    if is_daily
      bottom = streak\truncate_date date y, m - 4, 1
      bottom\adddays 1
    else
      bottom = streak\truncate_date y - 1, 1, 1
      bottom\adddays 1

    start_date = streak\start_datetime!
    current_date = date true

    cutoff_date = @props.start_date and date @props.start_date

    coroutine.wrap ->
      while bottom < current_date and start_date < current_date
        break if cutoff_date and current_date < cutoff_date
        coroutine.yield streak\truncate_date current_date
        streak\increment_date_by_unit current_date, -1

  render_grouped: (each_unit) =>
    {:streak} = @props

    highlight_unit = @get_highlight_date!

    units = for unit_date_utc in each_unit
      unit_date = unit_date_utc\copy!
      unit_date\addhours(streak.hour_offset)
      formatted_date = unit_date\fmt Streaks.day_format_str
      unit_count = @unit_counts and @unit_counts[formatted_date] or 0

      {
        count: @unit_counts and unit_count or nil
        date: unit_date\copy!
        :formatted_date
      }

    is_daily = streak.rate == Streaks.rates.daily
    unit_group = if is_daily
      (unit) -> unit.date\fmt "%Y-%m"
    else
      (unit) -> unit.date\fmt "%Y"

    by_group = {}

    for unit in *units
      group_name = unit_group unit
      unless by_group[group_name]
        by_group[group_name] = {}
        table.insert by_group, group_name

      table.insert by_group[group_name], unit

    for group in *by_group
      group_units = by_group[group]
      group_units = [group_units[i] for i=#group_units,1,-1]

      first_unit = group_units[1]
      continue unless first_unit

      all_empty = true
      if @unit_counts
        for unit in *group_units
          count = @unit_counts and @unit_counts[unit.formatted_date] or 0
          if count > 0
            all_empty = false
            break
      else
        all_empty = false

      if all_empty
        -- if it's a recent group then still show it
        back = date(true)\adddays -30
        if back < first_unit.date
          all_empty = false

        last_unit = group_units[#group_units]
        if back < last_unit.date
          all_empty = false

      if all_empty and @props.hide_empty
        continue

      section class: {"unit_group", :all_empty}, ->
        div class: "unit_group_header", group

        div class: "unit_group_units", ->
          if is_daily
            dow = first_unit.date\getisoweekday()
            dow = dow % 7
            for i=1,dow
              div class: "streak_unit spacer"

          for unit in *group_units
            @render_unit unit, highlight_unit

  render_units: (each_unit) =>
    highlight_unit = @get_highlight_date!

    for unit_date_utc in each_unit
      unit_date = unit_date_utc\copy!
      unit_date\addhours(@props.streak.hour_offset)
      formatted_date = unit_date\fmt Streaks.day_format_str

      unit_count = if @props.unit_counts
        @props.unit_counts[formatted_date] or 0

      @render_unit {
        count: unit_count
        date: unit_date\copy!
        :formatted_date
      }, highlight_unit

  render_unit: (unit, highlight_unit_date) =>
    {:streak} = @props

    formatted_date = unit.formatted_date
    submission_id = @props.completed_units[formatted_date]
    unit_count = @props.unit_counts and @props.unit_counts[formatted_date] or 0

    @today_unit = streak\truncate_date date true unless @today_unit
    today_unit = @today_unit

    show_count = false

    classes = "streak_unit"
    classes ..= " submitted" if submission_id
    classes ..= " empty" if @props.unit_counts and unit_count == 0

    before_unit = unit.date < today_unit
    if before_unit
      classes ..= " before_current_unit"
      show_count = true

    if 0 == date.diff(highlight_unit_date, unit.date)\spandays!
      classes ..= " current_unit"
      show_count = true

    unit_url = @url_for "view_streak_unit", {
      date: formatted_date
      id: streak.id
    }, submission_id and @props.user_id and {user_id: @props.user_id} or nil

    pretty_date = streak\format_date_unit unit.date

    tooltip = if not show_count or not @props.unit_counts
      pretty_date
    else
      "#{pretty_date}: #{@plural unit_count, "submission", "submissions"}"

    if submission_id
      tooltip ..= " - Submitted"

    dow = unit.date\getisoweekday()
    dow = dow % 7

    grid_cell = ->
      div {
        class: classes
        "data-date": tostring unit.date
        "data-tooltip": tooltip
        @props.unit_counts and show_count and unit.count or nil
      }

    if not @current_user and unit_count == 0
      grid_cell!
    else
      a href: unit_url, grid_cell

