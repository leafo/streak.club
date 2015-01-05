
import to_json from require "lapis.util"
import Streaks from require "models"

class EditSubmission extends require "widgets.base"
  @needs: {"submission", "uploads"}

  @include "widgets.form_helpers"

  js_init: =>
    data = {
      uploads: @uploads and [{
        id: u.id
        filename: u.filename
        size: u.size
        position: u.position
      } for u in *@uploads]
      submission: @submission and {
        id: @submission.id
      }
    }

    "new S.EditSubmission(#{@widget_selector!}, #{to_json data});"

  inner_content: =>
    div class: "page_header", ->
      if @submission
        h2 "Edit submission"
        h3 ->
          text "A submission for"
          num_streaks = #@streaks
          for i, streak in ipairs @streaks
            text " "
            a href: @url_for(streak), streak.title
            text ", " unless i == num_streaks

      else
        h2 "Submit to streak"
        if @unit_date
          h3 "Submiting for #{@unit_date\fmt Streaks.day_format_str}"

    if @streak
      p "Submitting to #{@streak.title}"

    submission = @params.submission or @submission or {}

    @render_errors!

    form class: "form primary_form", method: "POST", ->
      input type: "hidden", name: "json", value: "yes"
      @csrf_input!

      @text_input_row {
        label: "Title"
        name: "submission[title]"
        value: submission.title
      }

      @text_input_row {
        label: "Description"
        name: "submission[description]"
        type: "textarea"
        value: submission.description
      }

      @text_input_row {
        label: "Tags"
        sub: "Classify your submission for easy browsing later (10 max). Press enter to add"
        name: "submission[tags]"
      }

      div class: "file_uploader", ->
        div class: "file_upload_list"

        button {
          class: "new_upload_btn button"
          "data-url": @url_for("prepare_upload") .. "?type=image"
          "Add file(s)"
        }

      div class: "button_row", ->
        button class: "button", ->
          if @submission
            text "Save"
          else
            text "Submit"

        if @submission
          text " or "
          a href: @url_for(@submission), "Return to submission"

    @js_template "file_upload", =>
      div class: "file_upload", ->
        input type: "hidden", name: "upload[{{ id }}][position]", value: "{{ position }}"

        div ->
          span class: "filename", "{{ filename }}"
          text " "
          span class: "file_size", " ({{ _.str.formatBytes(size) }})"

          div class: "upload_progress", ->
            div class: "upload_progress_inner"

          div class: "upload_error"

          div class: "upload_success", "Success"


