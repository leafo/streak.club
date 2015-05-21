
class HomeHeader extends require "widgets.base"
  @include "widgets.tabs_helpers"
  page_name: "index"

  base_widget: false

  inner_content: =>
    div class: "page_tabs", ->
      @page_tab "Your streaks", "index", @url_for "index"
      @page_tab "Following feed", "following_feed", @url_for "following_feed"
      @page_tab "Your profile", "profile", @url_for @current_user
      @page_tab "New this week", "profile", @url_for "stats_this_week"
