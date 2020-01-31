
SubmissionList = require "widgets.submission_list"
UserHeader = require "widgets.user_header"

import sanitize_html, is_empty_html, convert_links from require "helpers.html"

class UserProfile extends require "widgets.page"
  @needs: {"user", "user_profile", "submissions", "active_streaks", "completed_streaks", "upcoming_streaks"}
  @include "widgets.streak_helpers"

  page_name: "profile"
  responsive: true

  js_init: =>
    "new S.UserProfile(#{@widget_selector!});"

  inner_content: =>
    widget UserHeader page_name: @page_name

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    div class: "columns", ->
      div class: "submission_column", ->
        website = @user_profile\format_website!
        twitter = @user_profile\twitter_handle!

        ul class: "user_links", ->
          if website
            li class: "user_website", ->
              img height: 15, src: "/static/images/link.svg"
              a rel: "nofollow noopener", href: website,
                @truncate @user_profile.website

          if twitter
            li class: "user_twitter", ->
              img height: 15, src: "/static/images/twitter.svg"
              a href: "http://twitter.com/#{twitter}", "@" .. twitter


        if @user_profile.bio and not is_empty_html @user_profile.bio
          div class: "user_formatted user_bio", ->
            raw sanitize_html convert_links @user_profile.bio

        @render_submissions!

      div class: "streak_column", ->
        @render_streaks "Active streaks", @active_streaks
        completed_streaks = if @completed_streaks
          for streak in *@completed_streaks
            continue unless streak.completed_units and next streak.completed_units
            streak

        @render_streaks "Completed streaks", completed_streaks
        @render_streaks "Upcoming streaks", @upcoming_streaks

  render_submissions: =>
    unless next @submissions
      p class: "empty_message", ->
        text "#{@user\name_for_display!} hasn't submitted anything yet."

      return

    h2 ->
      text "All submissions "
      span class: "sub", "(#{@user\submissions_count_for @current_user})"

    widget SubmissionList {
      hide_hidden: true
    }

  render_streaks: (title, streaks) =>
    return unless next streaks
    h2 title
    div class: "sidebar_streak_list", ->
      for streak in *streaks
        @render_streak_row streak, hide_units_if_not_submitted: true
