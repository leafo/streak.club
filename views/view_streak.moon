
date = require "date"
import time_ago_in_words, to_json from require "lapis.util"

class ViewStreak extends require "widgets.base"
  @needs: {"streak", "streak_users"}

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

    form action: "", method: "post", ->
      @csrf_input!
      if @streak_user
        button name: "action", value: "leave_streak", "Leave streak"
      else
        button name: "action", value: "join_streak", "Join streak"

    if @streak\allowed_to_submit @current_user
      a href: @url_for("new_streak_submission", id: @streak.id), "New submission"

    @render_participants!

  render_streak_units: =>
    today = date true

    start_date = date @streak.start_date
    end_date = date @streak.end_date

    assert start_date < end_date

    current_date = date start_date

    div class: "streak_units", ->
      while current_date < end_date
        div {
          class: "streak_unit #{current_date < today and "before_today" or ""}"
          "data-date": tostring current_date
          "data-tooltip": @streak\format_date_unit current_date
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

