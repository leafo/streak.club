MarkdownEditor = require "widgets.markdown_editor"

class AdminEmailStreak extends require "widgets.admin.page"
  @needs: {"streak"}
  @include "widgets.form_helpers"

  @es_module: [[
    import {AdminEmailStreak} from "admin/admin_email_streak"
    new AdminEmailStreak(widget_selector)
  ]]

  column_content: =>
    div class: "page_header", ->
      h2 "Email streak users"
      h3 ->
        a href: @url_for(@streak), @streak.title
        raw " &middot; "
        a href: @admin_url_for(@streak), "Return to admin"

    form class: "form", method: "post", ->
      @csrf_input!

      @text_input_row {
        label: "Subject"
        name: "email[subject]"
      }

      @input_row "Body", ->
        widget MarkdownEditor {
          label: "Body"
          name: "email[body]"
        }

      @input_row "Options", ->
        @radio_buttons "action", {
          {"dry_run", "Dry run", "Just print email addresses this would be sent to"}
          {"preview", "Preview", "Just send the email once to the config.admin_email"}
          {"send", "Send", "Send to everyone"}
        }

      div class: "button_row", ->
        button class: "button", "Save"
