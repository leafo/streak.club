
class HomeHeader extends require "widgets.base"
  @include "widgets.tabs_helpers"
  page_name: "index"

  base_widget: false

  inner_content: =>
    div class: "page_tabs", ->
      @page_tab "Your streaks", "index", @url_for "index"
      feed_tab = ->
        @page_tab "Following feed", "following_feed", @url_for "following_feed"

      if @unseen_feed_count and @unseen_feed_count > 0
        span class: "tab_wrapper", ->
          span class: "tab_bubble", @unseen_feed_count
          feed_tab!
      else
        feed_tab!

      @page_tab "Your profile", "profile", @url_for @current_user
      @page_tab "New this week", "profile", @url_for "stats_this_week"
