
date = require "date"
import time_ago_in_words, to_json from require "lapis.util"

class ViewStreak extends require "widgets.base"
  @needs: {"streak"}

  js_init: =>
    opts = {}
    "new S.ViewStreak(#{@widget_selector!}, #{to_json opts})"

  inner_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "admin_tools", ->
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"

    h2 @streak.title
    h3 @streak.short_description
    p ->
      text "Starts #{time_ago_in_words @start_date} (#{@streak.start_date}).
        Ends #{time_ago_in_words @streak.end_date} (#{@streak.end_date})"

    @render_streak_units!

    form action: "", method: "post", ->
      @csrf_input!
      if @streak_user
        button name: "action", value: "leave_streak", "Leave streak"
      else
        button name: "action", value: "join_streak", "Join streak"

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

