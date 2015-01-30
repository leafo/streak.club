
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

    div class: "page_header", ->
      h2 @streak.title
      h3 @streak.short_description

    div class: "page_tabs", ->
      @page_tab "Overview", "overview", @url_for(@streak)
      @page_tab "Participants",
        "participants",
        @url_for("view_streak_participants", slug: @streak\slug!, id: @streak.id),
        "(#{@streak.users_count})"


