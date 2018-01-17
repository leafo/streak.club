
HomeHeader = require "widgets.home_header"
StreakList = require "widgets.streak_list"

class Dashboard extends require "widgets.page"
  @include "widgets.tabs_helpers"
  @needs: {"active_streaks", "current_streaks", "notifications"}

  responsive: true

  inner_content: =>
    widget HomeHeader page_name: "index"

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    div class: "columns", ->
      div class: "primary_column", ->
        h2 "Active streaks you're in"

        if next @active_streaks
          @render_streaks @active_streaks, {
            show_submit_button: true
          }
        else
          p class: "empty_message", ->
            text "You aren't part of any yet, "
            a href: @url_for("streaks"), "go find some"
            text "."

        if next @created_streaks
          h2 "Streaks you've created"
          @render_streaks @created_streaks

        if next @completed_streaks
          h2 "Streaks you've completed"
          @render_streaks @completed_streaks

        if @featured_streaks and next @featured_streaks
          h2 "Featured streaks"
          @render_streaks @featured_streaks, show_short_description: true

      div class: "side_column", ->
        div class: "sidebar_buttons", ->
          a class: "button", href: @url_for("streaks"), "Browse streaks"
          a class: "button outline_button", href: @url_for("new_streak"), "Create a new streak"

        p class: "side_notification", ->
          strong "Hey!"
          br!
          text " Follow "
          a href: "https://twitter.com/thestreakclub", "@thestreakclub"
          text " on Twitter for site updates and interesting streaks and
          submissions."

  render_streaks: (streaks, opts={}) =>
    widget StreakList {
      :streaks
      show_submit_button: opts.show_submit_button
      show_short_description: opts.show_short_description
    }
