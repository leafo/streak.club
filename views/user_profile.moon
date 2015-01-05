
StreakUnits = require "widgets.streak_units"
SubmissionList = require "widgets.submission_list"

class UserProfile extends require "widgets.base"
  @needs: {"user", "submissions", "streaks"}
  @include "widgets.follow_helpers"

  js_init: =>
    "new S.UserProfile(#{@widget_selector!});"

  inner_content: =>
    if not @current_user or @current_user.id != @user.id
      div class: "header_right", ->
        @follow_button @user, @following

    div class: "page_header", ->
      h2 @user\name_for_display!
      h3 ->
        text "A user registered #{@format_timestamp @user.created_at}"
        raw " &middot; "
        text @plural @user.submission_count, "submission", "submissions"

    div class: "columns", ->
      div class: "submission_column", ->
        @render_submissions!

      div class: "streak_column", ->
        @render_streaks!

  render_submissions: =>
    return unless next @submissions
    h2 "All submissions"
    widget SubmissionList

  render_streaks: =>
    return unless next @streaks
    h2 "Active streaks"
    div class: "streak_list", ->
      for streak in *@streaks
        div class: "streak_row", ->
          h3 ->
            a href: @url_for(streak), streak.title

          h4 streak.short_description
          p class: "streak_sub", ->
            text "#{streak\interval_noun!} from "
            nobr streak.start_date
            text " to "
            nobr streak.end_date

          widget StreakUnits streak: streak, completed_units: streak.completed_units

