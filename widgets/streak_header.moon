
class StreakHeader extends require "widgets.base"
  @include "widgets.tabs_helpers"

  base_widget: false

  inner_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "owner_tools", ->
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"

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
      h2 @streak.title
      h3 @streak.short_description

    div class: "page_tabs", ->
      url_params = { slug: @streak\slug!, id: @streak.id }

      @page_tab "Overview", "overview", @url_for(@streak)
      @page_tab "Participants",
        "participants",
        @url_for("view_streak_participants", url_params),
        "(#{@streak.users_count})"

      @page_tab "Top streaks", "top_participants", @url_for "streak_top_participants", url_params
      @page_tab "Top submissions", "top_submissions", @url_for "streak_top_submissions", url_params
      @page_tab "Stats", "stats", @url_for "streak_stats", url_params

