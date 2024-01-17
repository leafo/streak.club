
import Streaks from require "models"
BrowseStreaksFlow = require "flows.browse_streaks"

class StreakHeader extends require "widgets.base"
  @include "widgets.tabs_helpers"

  show_breadcrumbs: true

  widget_classes: =>
    super! .. " tab_header"

  inner_content: =>
    if @streak\is_draft!
      a {
        href: @url_for("edit_streak", id: @streak.id) .. "#publish_status"
        class: "draft_banner"
        "This streak is currently a draft and unpublished"
      }

    if @streak\is_hidden!
      div {
        class: "hidden_banner"
        "This streak is hidden and only visible to those with the URL"
      }

    div class: "page_header", ->
      if @show_breadcrumbs
        div class: "breadcrumbs", ->
          a href: @url_for("streaks"), "Streaks"

          if @streak.category
            text " › "
            category = Streaks.categories\to_name @streak.category
            cat_url = @flow("browse_streaks")\filtered_url { :category }
            cat_name = BrowseStreaksFlow.filter_names.category[category]

            a href: cat_url, cat_name

          text " › "
          state = @streak\state_name!
          state_url = @flow("browse_streaks")\filtered_url { :state }
          state_name = BrowseStreaksFlow.filter_names.state[state]
          a href: state_url, state_name

      h2 ->
        a href: @url_for(@streak), @streak.title

      if @sub_header
        @sub_header!
      else
        h3 @streak.short_description

    div class: "page_tabs", ->
      div class: "tabs_inner", ->
        url_params = { slug: @streak\slug!, id: @streak.id }

        @insert_tab! if @insert_tab

        @page_tab "Overview", "overview", @url_for(@streak)
        @page_tab "Participants",
          "participants",
          @url_for("streak_participants", url_params),
          "(#{@streak\approved_participants_count!})"

        if @streak\has_community!
          category = @streak\get_community_category!
          has_unread = if @route_name != "community.streak"
            @streak\has_unread_community_topics @current_user

          has_count = category and category.topics_count > 0

          @page_tab "Discussion", "community",
            @url_for("community.streak", url_params),
            has_count and ->
              if has_unread
                strong "(#{category.topics_count})"
              else
                text "(#{category.topics_count})"

        @page_tab "Leaderboard", "top_participants", @url_for "streak_top_participants", url_params
        @page_tab "Top submissions", "top_submissions", @url_for "streak_top_submissions", url_params
        @page_tab "Stats", "stats", @url_for "streak_stats", url_params
        if @page_name == "calendar"
          @page_tab "Calendar", "calendar", @url_for "streak.calendar", url_params

        if @streak\allowed_to_edit @current_user
          a href: @url_for("edit_streak", id: @streak.id), class: "tab_button", "Edit streak"

