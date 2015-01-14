
StreakList = require "widgets.streak_list"

class IndexLoggedIn extends require "widgets.base"
  inner_content: =>
    div class: "columns", ->
      div class: "primary_column", ->
        h2 "Streaks you're in"

        if next @active_streaks
          @render_streaks @active_streaks
        else
          p class: "empty_message", "You aren't part of any streaks yet"

        if next @created_streaks
          h2 "Streaks you've created"
          @render_streaks @created_streaks

      div class: "side_column", ->
        div class: "sidebar_buttons", ->
          a class: "button", href: @url_for("streaks"), "Browse streaks"
          a class: "button outline_button", href: @url_for("new_streak"), "Create a new streak"


  render_streaks: (streaks) =>
    widget StreakList(:streaks)
