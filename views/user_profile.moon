
StreakUnits = require "widgets.streak_units"
SubmissionList = require "widgets.submission_list"

import sanitize_html, is_empty_html from require "helpers.html"

class UserProfile extends require "widgets.base"
  @needs: {"user", "user_profile", "submissions", "streaks"}
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
        div class: "user_stat", ->
          text "A user registered #{@relative_timestamp @user.created_at}"

        if @user.submissions_count > 0
          div class: "user_stat",
            @plural @user.submissions_count, "submission", "submissions"

        if @user.followers_count > 0
          div class: "user_stat",
            @plural @user.followers_count, "follower", "followers"

        if @user.following_count > 0
          div class: "user_stat", "Following #{@user.following_count}"

        if @user.comments_count > 0
          div class: "user_stat",
            @plural @user.comments_count, "comment", "comments"

        if @user.likes_count > 0
          div class: "user_stat",
            @plural @user.likes_count, "like", "likes"

        if @user.streaks_count > 0
          div class: "user_stat",
            @plural @user.streaks_count, "streak", "streaks"


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
    h2 "All submissions"
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

