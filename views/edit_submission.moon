

class EditSubmission extends require "widgets.base"
  @include "widgets.form_helpers"

  js_init: =>
    "new S.EditSubmission(#{@widget_selector!});"

  inner_content: =>
    if @submission
      h2 "Edit submission"
    else
      h2 "Submit to streak"

    if @streak
      p "Submitting to #{@streak.title}"

    submission = @params.submission or @submission or {}

    @render_errors!

    form class: "form", method: "POST", ->
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

      div class: "file_uploader", ->
        div class: "file_upload_list"

        button {
          class: "new_upload_btn button"
          "data-url": @url_for("prepare_upload") .. "?type=image"
          "Upload file"
        }

      div class: "button_row",
        button class: "button", "Submit"

    @js_template "file_upload", =>
      div class: "file_upload", ->
        div ->
          span class: "filename", "{{ filename }}"
          text " "
          span class: "file_size", " ({{ _.str.formatBytes(size) }})"

          div class: "upload_progress", ->
            div class: "upload_progress_inner"

          div class: "upload_error"

          div class: "upload_success", "Success"


