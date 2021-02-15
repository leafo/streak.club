
class AdminPage extends require "widgets.page"
  @include "widgets.tabs_helpers"

  inner_content: =>
    div class: "tab_header", ->
      div class: "page_tabs", ->
        div class: "tabs_inner", ->
          @page_tab "Users", "users", @url_for "admin.users"
          @page_tab "Spam", "spam", @url_for "admin.spam_queue"
          @page_tab "Exceptions", "exceptions", @url_for "admin.exceptions"

    if @column_content
      div class: "inner_column", ->
        @column_content!
