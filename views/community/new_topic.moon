StreakHeader = require "widgets.streak_header"
MarkdownEditor = require "widgets.markdown_editor"

import to_json from require "lapis.util"

class CommunityNewTopic extends require "widgets.page"
  @include "widgets.form_helpers"
  @needs: {"category"}

  page_name: "community"

  js_init: =>
    "new S.CommunityNewTopic(#{@widget_selector!})"

  inner_content: =>
    widget StreakHeader page_name: @page_name
    div class: "inner_column", ->
      @column_content!

  column_content: =>
    h2 "New topic"

    @render_errors!

    form method: "post", class: "form", ->
      @csrf_input!

      @text_input_row {
        label: "Title"
        name: "topic[title]"
        required: true
        placeholder: "Required"
        autofocus: true
      }

      @input_row "Body", ->
        widget MarkdownEditor {
          required: true
          name: "topic[body]"
          placeholder: "Required"
        }

      if @streak\is_host @current_user
        p "All participants will be notified of this topic since you are an
        owner of this streak."

      -- if @category\allowed_to_moderate @current_user
      --   fieldset ->
      --     legend "Moderator"

      --     @input_row "Options", ->
      --       @checkboxes "topic", {
      --         {"sticky", "Sticky"}
      --         {"locked", "Locked"}
      --       }

      div class: "buttons", ->
        button class: "button", "New topic"
