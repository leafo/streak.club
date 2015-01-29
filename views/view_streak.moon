
import login_and_return_url from require "helpers.app"
import sanitize_html, is_empty_html from require "helpers.html"
import time_ago_in_words, to_json from require "lapis.util"

date = require "date"

StreakUnits = require "widgets.streak_units"
SubmissionList = require "widgets.submission_list"
Countdown = require "widgets.countdown"
WelcomeBanner = require "widgets.welcome_banner"
StreakHeader = require "widgets.streak_header"

class ViewStreak extends require "widgets.base"
  @needs: {"streak", "streak_users", "unit_counts", "completed_units"}

  page_name: "overview"

  js_init: =>
    current_unit = @streak\current_unit!

    opts = {
      start: @streak\start_datetime!\fmt "${iso}Z"
      end: @streak\end_datetime!\fmt "${iso}Z"
      unit_start: current_unit and current_unit\fmt "${iso}Z"
      unit_end: current_unit and @streak\increment_date_by_unit(current_unit)\fmt "${iso}Z"

      before_start: @streak\before_start!
      after_end: @streak\after_end!
    }
    "new S.ViewStreak(#{@widget_selector!}, #{to_json opts});"

  inner_content: =>
    unless @current_user
      widget WelcomeBanner

    if @current_user and @current_user\is_admin!
      @admin_tools!

    widget StreakHeader page_name: @page_name

    div class: "columns", ->
      div class: "streak_feed_column",->
        @streak_summary!
        @render_submissions!

      div class: "streak_side_column", ->
        @render_countdown!

        if @current_submit
          a {
            href: @url_for(@current_submit\get_submission!)
            class: "button outline_button"
            "View submission"
          }

          p class: "submit_sub", "You already submitted for #{@streak\unit_noun!}. "

        elseif @streak\allowed_to_submit @current_user
          a {
            href: @url_for("new_submission") .. "?streak_id=#{@streak.id}"
            class: "button"
            "New submission"
          }

          p class: "submit_sub", "You haven't submitted #{@streak\unit_noun!} yet."


        if @streak_user and not @streak\before_start!
          current = @streak_user\current_streak!
          longest = @streak_user\longest_streak!

          div class: "streak_summary", ->
            span class: "stat", "Streak: #{current}"
            span class: "stat", "Longest: #{longest}"

        if not @streak_user and not @streak\after_end!
          form action: "", method: "post", class: "form", ->
            @csrf_input!

            if @current_user
              button class: "button", name: "action", value: "join_streak", "Join streak"
            else
              a {
                class: "button"
                href: login_and_return_url @
                "Join streak"
              }

        @render_streak_units!

        if @streak_user
          form action: "", method: "post", class: "form leave_form", ->
            @csrf_input!
            button {
              class: "button outline_button"
              name: "action"
              value: "leave_streak"
              "Leave streak"
            }

        @render_participants!

  render_streak_units: =>
    widget StreakUnits

  streak_summary: =>
    p class: "date_summary", ->
      if @streak\during! or @streak\after_end!
        text "Started "
      else
        text "Starts "

      text "#{@relative_timestamp @streak.start_date}"
      text " ("
      @date_format @streak\start_datetime!
      text ")."
      br!

      if @streak\after_end!
        text "Ended"
      else
        text "Ends"

      text " #{@relative_timestamp @streak.end_date} "
      text " ("
      @date_format @streak\end_datetime!
      text ")."

    unless is_empty_html @streak.description
      div class: "user_formatted", ->
        raw sanitize_html @streak.description

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


  render_submissions: =>
    unless next @submissions
      p class: "empty_message", ->
        if @page == 1
          if @streak\before_start!
            text "Come back after the streak has started to browse submissions"
          else
            text "No submissions yet"
        else
          text "No submissions on this page"

      return

    h4 "Recent submissions"
    widget SubmissionList

  render_countdown: =>
    if @streak\before_start!
      widget Countdown {
        header_content: =>
          text "Starts in"
      }
      return

    return if @streak\after_end!

    widget Countdown {
      header_content: =>
        if @current_submit
          text "Time remaining"
        else
          text "Time left to submit"

        span class: "sub",
          "#{@streak\interval_noun false} ##{@streak\unit_number_for_date(date true)}"
    }

  admin_tools: =>
    feature = @streak\get_featured_streak!

    div class: "admin_tools", ->
      form action: @url_for("admin_featured_streak", id: @streak.id), method: "POST", ->
        @csrf_input!
        if feature
          p "Position: #{feature.position}"
          input type: "hidden", name: "action", value: "delete"
          button "Unfeature"
        else
          input type: "hidden", name: "action", value: "create"
          button "Feature"

