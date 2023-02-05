

types = require "lapis.validate.types"

not_empty = -types.empty

class AdminPage extends require "widgets.page"
  @include "widgets.tabs_helpers"

  @asset_packages: {"admin"}
  filter_form: (fn) =>

    field_names = {}

    render_field = (name, opts={}) ->
      table.insert field_names, name

      input {
        type: opts.type or "text"
        value: @params[name]
        name: name
        title: name
        class: "filter_field"
        placeholder: opts.placeholder or name
      }

    has_filter = ->
      for name in *field_names
        return true if not_empty @params[name]

      false

    form {
      class: "filter_form form"
    }, ->
      fn render_field
      button type: "submit", style: "display: none;"
      -- Note this functions as submit button that also clears
      if has_filter!
        button class: "button", onclick: "$('.filter_form .filter_field').val('')", "Clear"

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
