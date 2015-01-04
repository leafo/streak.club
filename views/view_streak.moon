
date = require "date"
import time_ago_in_words, to_json from require "lapis.util"

class ViewStreak extends require "widgets.base"
  @needs: {"streak", "streak_users", "unit_counts", "completed_units"}

  js_init: =>
    opts = {}
    "new S.ViewStreak(#{@widget_selector!}, #{to_json opts})"

  inner_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "admin_tools", ->
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"

    h2 @streak.title
    h3 @streak.short_description

    @streak_summary!
    @render_streak_units!

    form action: "", method: "post", class: "form", ->
      @csrf_input!
      if @streak_user
        button class: "button",name: "action", value: "leave_streak", "Leave streak"
      else
        button class: "button", name: "action", value: "join_streak", "Join streak"

    if @current_submit
      p ->
        text "You already submitted for #{@streak\unit_noun!}. "
        a href: @url_for(@current_submit\get_submission!), "View submission"

    elseif @streak\allowed_to_submit @current_user
      a href: @url_for("new_streak_submission", id: @streak.id), "New submission"

    @render_participants!

  render_streak_units: =>
    day_str = "%Y-%m-%d"
    today = date date(true)\getdate!

    formatted_today = today\fmt day_str

    start_date = @streak\start_datetime!
    end_date = @streak\end_datetime!

    assert start_date < end_date

    current_date = date start_date

    div class: "streak_units", ->
      while current_date < end_date
        formatted_date = current_date\fmt day_str
        submission_id = @completed_units and @completed_units[formatted_date]
        count = @unit_counts[formatted_date] or 0

        classes = "streak_unit"
        classes ..= " before_today" if current_date < today
        classes ..= " today" if formatted_date == formatted_today
        classes ..= " submitted" if submission_id

        pretty_date = @streak\format_date_unit current_date

        tooltip = if today < current_date
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

  streak_summary: =>
    p ->
      if @streak\during! or @streak\after_end!
        text "Started "
      else
        text "Starts "

      text "#{@format_timestamp @streak.start_date} (#{@streak\start_datetime!}). "

      if @streak\after_end!
        text "Ended"
      else
        text "Ends"

      text " #{@format_timestamp @streak.end_date} (#{@streak\end_datetime!})."

  render_participants: =>
    h3 ->
      text "Participants"
      if @streak.users_count > 0
        text " "
        span class: "header_count", "(#{@streak.users_count})"

    unless next @streak_users
      if @streak\after_end!
        p "No one is participated in this streak"
      else
        p "No one is participating in this streak yet"
      return

    ul class: "streak_participants", ->
      for su in *@streak_users
        li class: "streak_user", ->
          a href: @url_for(su.user), su.user\name_for_display!

