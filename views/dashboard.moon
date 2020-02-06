
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
        @render_account_stats!

        h2 "Active streaks you're in"

        if next @active_streaks
          @render_streaks @active_streaks, {
            show_submit_button: true
            as_participant: true
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
          @render_streaks @completed_streaks, {
            as_participant: true
          }

        if @featured_streaks and next @featured_streaks
          h2 "Featured streaks"
          @render_streaks @featured_streaks, show_short_description: true

      div class: "side_column", ->
        div class: "sidebar_buttons", ->
          a class: "button", href: @url_for("streaks"), "Browse streaks"
          a class: "button outline_button", href: @url_for("new_streak"), "Create a new streak"

        div class: "side_notification", ->
          strong "Hey!"

          ul ->
            li ->
              a href: "https://discord.gg/f9P9Grt", "Join Streak Club on Discord"

            li ->
              text " Follow "
              a href: "https://twitter.com/thestreakclub", "@thestreakclub"
              text " on Twitter"

  render_streaks: (streaks, opts={}) =>
    widget StreakList {
      :streaks
      show_submit_button: opts.show_submit_button
      show_short_description: opts.show_short_description
      as_participant: opts.as_participant
    }

  render_account_stats: =>
    h2 "Account stats"
    section class: "account_stats", ->
      div class: "stats_block", ->
        div class: "value", @number_format @current_user\submissions_count_for @current_user
        div class: "label", "Posts"

      likes = @current_user\get_likes_received!
      div class: "stats_block", ->
        div class: "value", @number_format likes
        div class: "label", "Likes"


      comments = @current_user\get_comments_received!
      div class: "stats_block", ->
        div class: "value", @number_format comments
        div class: "label", "Comments"

      div class: "stats_block", ->
        div class: "value", @number_format @current_user.followers_count
        div class: "label", "Followers"

