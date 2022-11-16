
class AdminPage extends require "widgets.page"
  @include "widgets.tabs_helpers"

  @asset_packages: {"admin"}

  inner_content: =>
    div class: "tab_header", ->
      div class: "page_tabs", ->
        div class: "tabs_inner", ->
          @page_tab "Users", "users", @url_for "admin.users"
          @page_tab "Spam", "spam", @url_for "admin.spam_queue"
          @page_tab "Exceptions", "exceptions", @url_for "admin.exceptions"
          @page_tab "Streaks", "streaks", @url_for "admin.streaks"
          @page_tab "Comments", "comments", @url_for "admin.comments"
          @page_tab "Community Posts", "community_posts", @url_for "admin.community_posts"
          @page_tab "Uploads", "uploads", @url_for "admin.uploads"

    if @column_content
      div class: "inner_column", ->
        @column_content!
