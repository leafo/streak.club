
StreakUnits = require "widgets.streak_units"
SubmissionList = require "widgets.submission_list"
UserHeader = require "widgets.user_header"

import sanitize_html, is_empty_html from require "helpers.html"

class UserProfile extends require "widgets.base"
  @needs: {"user", "user_profile", "submissions", "streaks"}
  @include "widgets.follow_helpers"

  page_name: "profile"

  js_init: =>
    "new S.UserProfile(#{@widget_selector!});"

  inner_content: =>
    if not @current_user or @current_user.id != @user.id
      div class: "header_right", ->
        @follow_button @user, @following

    widget UserHeader page_name: @page_name

    div class: "columns", ->
      div class: "submission_column", ->
        if @user_profile.bio and not is_empty_html @user_profile.bio
          div class: "user_formatted", ->
            raw sanitize_html @user_profile.bio

        if website = @user_profile\format_website!
          p class: "user_website", ->
            a rel: "nofollow", href: website, @truncate @user_profile.website

        if twitter = @user_profile\twitter_handle!
          p class: "user_twitter", ->
            a href: "http://twitter.com/#{twitter}", "@" .. twitter

        @render_submissions!

      div class: "streak_column", ->
        @render_streaks!

  render_submissions: =>
    return unless next @submissions
    h2 ->
      text "All submissions "
      span class: "sub", "(#{@user.submissions_count})"

    widget SubmissionList

  render_streaks: =>
    return unless next @streaks
    h2 "Active streaks"
    div class: "sidebar_streak_list", ->
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

          p class: "streak_sub", ->
            current = streak.streak_user\current_streak!
            longest = streak.streak_user\longest_streak!
            text "Streak: #{current}, Longest: #{longest}"

          widget StreakUnits streak: streak, completed_units: streak.completed_units

