
import sanitize_html, is_empty_html from require "helpers.html"
import time_ago_in_words, to_json from require "lapis.util"

StreakUnits = require "widgets.streak_units"
SubmissionList = require "widgets.submission_list"

class ViewStreak extends require "widgets.base"
  @needs: {"streak", "streak_users", "unit_counts", "completed_units"}

  js_init: =>
    opts = {}
    "new S.ViewStreak(#{@widget_selector!}, #{to_json opts});"

  inner_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "admin_tools", ->
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"

    div class: "page_header", ->
      h2 @streak.title
      h3 @streak.short_description


    div class: "columns", ->
      div class: "streak_feed_column",->
        @streak_summary!
        @render_submissions!

      div class: "streak_side_column", ->

        if @current_submit
          p ->
            text "You already submitted for #{@streak\unit_noun!}. "
            a href: @url_for(@current_submit\get_submission!), "View submission"
          elseif @streak\allowed_to_submit @current_user
            a {
              href: @url_for("new_streak_submission", id: @streak.id)
              class: "button"
              "New submission"
            }

            p class: "submit_sub", "You haven't submitted #{@streak\unit_noun!} yet."

        unless @streak_user
          form action: "", method: "post", class: "form", ->
            @csrf_input!
            button class: "button", name: "action", value: "join_streak", "Join streak"

        @render_streak_units!

        if @streak_user
          form action: "", method: "post", class: "form", ->
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

      text "#{@format_timestamp @streak.start_date} (#{@streak\start_datetime!}). "
      br!

      if @streak\after_end!
        text "Ended"
      else
        text "Ends"

      text " #{@format_timestamp @streak.end_date} (#{@streak\end_datetime!})."


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
      p class: "empty_message", "No submissions yet"
      return

    h4 "Recent submissions"
    widget SubmissionList

