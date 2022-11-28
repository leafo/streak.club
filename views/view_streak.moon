
import login_and_return_url from require "helpers.app"
import sanitize_html, is_empty_html, convert_links from require "helpers.html"
import to_json from require "lapis.util"

date = require "date"

StreakUnits = require "widgets.streak_units"
SubmissionList = require "widgets.submission_list"
Countdown = require "widgets.countdown"
StreakHeader = require "widgets.streak_header"
UserList = require "widgets.user_list"

class ViewStreak extends require "widgets.page"
  @needs: {"streak", "streak_host", "unit_counts", "completed_units"}
  @include "widgets.twitter_card_helpers"

  responsive: true
  page_name: "overview"

  widget_classes: =>
    {
      super!
      current_user_joined: @streak_user
    }

  @es_module: [[
    import {ViewStreak} from "main/view_streak"
    new ViewStreak(widget_selector, widget_params)
  ]]

  js_init: =>
    current_unit = @streak\current_unit!
    super {
      start: @streak\start_datetime!\fmt "${iso}Z"
      end: @streak.end_date and @streak\end_datetime!\fmt "${iso}Z"
      unit_start: current_unit and current_unit\fmt "${iso}Z"
      unit_end: current_unit and @streak\increment_date_by_unit(current_unit)\fmt "${iso}Z"

      before_start: @streak\before_start!
      after_end: @streak\after_end!
    }

  inner_content: =>
    @content_for "meta_tags", ->
      @twitter_card_for_streak @streak, @card_images

    if not @embed_page and @current_user and @current_user\is_admin!
      @admin_tools!

    if @embed_page
      div class: "embed_footer", ->
        img class: "logo_image", src: "/static/images/rainbow-sm.png"
        a href: @url_for(@streak), class: "header_button", "View on Streak Club"
    else
      widget StreakHeader page_name: @page_name

    div class: "responsive_column", ->
      if @streak_user and @streak_user.pending
        div class: "pending_join_banner", "You've requested to join this streak
        but not have been approved by the owner yet. When you are approved you'll
        be able to post."

      div class: "columns", ->
        div class: "streak_feed_column",->
          unless @embed_page
            @streak_summary!

          @render_submissions!

        unless @embed_page
          div class: "streak_side_column", ->
            @render_side_column!

  render_streak_units: =>
    widget StreakUnits

  render_side_column: =>
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


    if @streak_user and not @streak\before_start! and not @streak_user.pending
      current = @streak_user\get_current_streak! or 0
      longest = @streak_user\get_longest_streak! or 0

      div class: "streak_summary", ->
        span class: "stat", "Submissions: #{@number_format @streak_user.submissions_count}"
        span class: "stat", "Streak: #{@number_format current}"
        span class: "stat", "Longest: #{@number_format longest}"

    if not @streak_user and not @streak\after_end!
      form action: "", method: "post", class: "form", ->
        @csrf_input!

        label = if @streak\is_members_only!
          "Request to join"
        else
          "Join streak"

        if @current_user
          button class: "button", name: "action", value: "join_streak", label
        else
          a {
            class: "button"
            href: login_and_return_url @
            label
          }

        if @streak\is_members_only!
          p class: "members_only_message", "You must be approved by streak
          owner to join."

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

    @render_community_preview!

    section class: "streak_host", ->
      h3 "Hosted by"
      widget UserList users: { @streak_host }, narrow: true

    ul class: "misc_links", ->
      li ->
        a href: @url_for("streak_embed", id: @streak.id), "Embed streak on another page"

  streak_summary: =>
    p class: "date_summary", ->
      if @streak\during! or @streak\after_end!
        text "Started "
      else
        text "Starts "

      text "#{@relative_timestamp @streak\start_datetime!}"
      text " ("
      @date_format @streak\start_datetime!
      text ")."

      if @streak\has_end!
        br!

        if @streak\after_end!
          text "Ended"
        else
          text "Ends"

        text " #{@relative_timestamp @streak\end_datetime!} "
        text " ("
        @date_format @streak\end_datetime!
        text ")."
      else
        text " Goes forever."

    unless is_empty_html @streak.description
      div class: "user_formatted streak_description", ->
        div class: "click_to_open_overlay"
        raw sanitize_html convert_links @streak.description

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

    if @category
      section class: "discussion_nag", ->
        img class: "svg_icon", src: "/static/images/help.svg", width: 24, height: 24
        span "Have a question for this streak?"
        a {
          href: login_and_return_url @, @url_for("community.new_topic", category_id: @category.id)
          class: "button"
        }, "Ask a question..."

    h3 class: "submission_list_title", ->
      text "Recent submissions"
      text " "
      span class: "sub", "(#{@number_format @streak.submissions_count} total)"

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

        if @streak\has_end!
          span class: "sub",
            "#{@streak\interval_noun false} ##{@streak\unit_number_for_date(date true)}"
        elseif @streak_user
          span class: "sub",
            "#{@streak\interval_noun false} ##{@streak_user\current_unit_number!}"
    }

  admin_tools: =>
    feature = @streak\get_featured_streak!

    div class: "admin_tools", ->
      a href: @admin_url_for(@streak), "Admin"

      form action: @url_for("admin.featured_streak", id: @streak.id), method: "POST", ->
        @csrf_input!
        if feature
          p "Position: #{feature.position}"
          input type: "hidden", name: "action", value: "delete"
          button "Unfeature"
        else
          input type: "hidden", name: "action", value: "create"
          button "Feature"

  render_community_preview: =>
    return unless @category
    return unless @category_topics and next @category_topics
    section class: "community_preview", ->
      h3 "Discuss"

      div class: "topic_list", ->
        for topic in *@category_topics
          has_unread = topic\has_unread @current_user
          last_post = topic\get_last_post!

          div class: "topic_row", ->
            div class: "topic_title", ->
              (has_unread and strong or text) ->
                a href: @url_for(topic), topic\name_for_display!

            div class: "topic_sub", ->
              topic_date = last_post and last_post.created_at or topic.created_at

              import format_date from require "helpers.datetime"
              abs, rel = format_date topic_date
              span title: abs, rel

              if user = last_post and last_post\get_user!
                text " by "
                a href: @url_for(user), user\name_for_display!

      p class: "discuss_links", ->
        a {
          href: @url_for("community.new_topic", category_id: @category.id)
          class: "button"
        }, "New topic"

