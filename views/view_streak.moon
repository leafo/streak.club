
date = require "date"
import time_ago_in_words from require "lapis.util"

class ViewStreak extends require "widgets.base"
  @needs: {"streak"}

  inner_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "admin_tools", ->
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"

    h2 @streak.title
    h3 @streak.short_description
    p ->
      text "Starts #{time_ago_in_words @start_date}.
        Ends #{time_ago_in_words @streak.end_date}"

    form action: "", method: "post", ->
      @csrf_input!
      if @streak_user
        button name: "action", value: "leave_streak", "Leave streak"
      else
        button name: "action", value: "join_streak", "Join streak"

  render_streak_units: =>
