
import to_json from require "lapis.util"
import Streaks, Submissions from require "models"
MarkdownEditor = require "widgets.markdown_editor"
TagInput = require "widgets.tag_input"

date = require "date"

shapes = require "helpers.shapes"

class EditSubmission extends require "widgets.page"
  @needs: {"submission", "uploads"}

  @include "widgets.form_helpers"

  responsive: true

  @es_module: [[
    import {EditSubmission} from "main/edit_submission"
    new EditSubmission(widget_selector, widget_params)
  ]]

  js_init: =>
    super {
      uploads: @uploads and shapes.to_json_array\transform [{
        ready: true
        id: u.id
        filename: u.filename
        size: u.size
        position: u.position
      } for u in *@uploads]
      submission: @submission and {
        id: @submission.id
      }
      suggested_tags: @suggested_tags
      uploader_opts: {
        prepare_url: @url_for "prepare_upload"
      }
    }

  column_content: =>
    @content_for "all_js", ->
      @include_jquery_ui!

    div class: "page_header", ->
      if @submission
        h2 "Edit submission"
        if next @streaks
          p ->
            text "A submission for"
            num_streaks = #@streaks
            for i, streak in ipairs @streaks
              text " "
              a href: @url_for(streak), streak.title
              text ", " unless i == num_streaks

        div class: "owner_tools", ->
          a href: @url_for("delete_submission", id: @submission.id), "Delete submission..."
          a href: @url_for("submission_streaks", id: @submission.id), "Edit streaks..."

        p ->
          a href: @url_for(@submission), "« Return to submission"

      elseif @submittable_streaks and next @submittable_streaks
        h2 "Submit to streak"
        if @unit_date
          h3 "Submiting for #{@unit_date\fmt Streaks.day_format_str}"
      else
        h2 "Post a submission"
        p "You are submitting to your personal streak. If you wish to submit to an existing streak please join it first before posting."

    submission = @params.submission or @submission or {}
    tags = if @submission
      [tag.slug for tag in *@submission\get_tags!]

    @render_errors!

    form class: "form primary_form", method: "POST", ->
      input type: "hidden", name: "json", value: "yes"
      @csrf_input!

      @streak_picker!

      @text_input_row {
        label: "Title"
        name: "submission[title]"
        value: submission.title
        placeholder: "Optional"
      }

      @input_row "Description",->
        widget MarkdownEditor {
          value: submission.description
          placeholder: "Optional"
          name: "submission[description]"
        }

      @input_row "How do you feel about this submission", ->
        @radio_buttons "submission[user_rating]", {
          {"good", "I'm proud of it"}
          {"neutral", "I'm neutral about it"}
          {"bad", "I'm not proud of it"}
        }, @submission and Submissions.user_ratings\to_name(@submission.user_rating) or "neutral"

      @input_row "Tags", "Classify your submission for easy browsing later (10 max). Press enter to add", ->
        widget TagInput {
          placeholder: "Optional"
          name: "submission[tags]"
          :tags
        }

      div class: "label", "Files"
      div class: "file_uploader" -- rendered via react

      div class: "button_row", ->
        button class: "button", ->
          if @submission
            text "Save"
          else
            text "Submit"

  streak_picker: =>
    return unless @submittable_streaks and next @submittable_streaks
    submit_date = @unit_date or date true

    selected = if @params.streak_id
      { [@params.streak_id]: true }
    else
      {}

    @input_row "Submit to", ->
      p "If you select no streaks then you will post to your personal account streak only."


      opts = for s in *@submittable_streaks
        unit_num = "#{s\interval_noun false} ##{s\unit_number_for_date(submit_date)}"
        {tostring(s.id), s.title, unit_num}

      @checkboxes "submit_to", opts, selected


