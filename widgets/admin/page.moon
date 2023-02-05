

types = require "lapis.validate.types"
import instance_of from  require "tableshape.moonscript"

import Enum from require "lapis.db.model"

is_enum = instance_of Enum

not_empty = -types.empty

class AdminPage extends require "widgets.page"
  @include "widgets.tabs_helpers"

  @asset_packages: {"admin"}
  filter_form: (fn) =>

    field_names = {}

    render_field = (name, opts={}, more_opts) ->
      table.insert field_names, name

      local list_id

      if is_enum opts
        enum = opts
        opts = more_opts or {}
        list_id = "enum_#{name}"
        datalist id: list_id, ->
          for val in *enum
            option value: val, val

      switch opts.type
        when "bool", "boolean"
          label ->
            input {
              type: "checkbox"
              name: name
              checked: not_empty @params[name]
              onchange: "$(event.target).closest('form').submit()"
              class: "filter_field"
            }
            text " "
            text name
        else
          input {
            type: opts.type or "text"
            value: @params[name]
            name: name
            title: name
            class: "filter_field"
            placeholder: opts.placeholder or name
            list: list_id
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
        button class: "button", onclick: "$('.filter_form .filter_field').val('').prop('checked', false)", "Clear"

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
