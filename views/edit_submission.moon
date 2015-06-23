
import to_json from require "lapis.util"
import Streaks, Submissions from require "models"

date = require "date"

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
      suggested_tags: @suggested_tags
      uploader_opts: {
        prepare_url: @url_for "prepare_upload"
      }
    }

    "new S.EditSubmission(#{@widget_selector!}, #{to_json data});"

  inner_content: =>
    @content_for "all_js", ->
      @include_jquery_ui!
      @include_tagit!
      @include_redactor!

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

    submission = @params.submission or @submission or {}
    tags_str = if @submission
      table.concat [tag.slug for tag in *@submission\get_tags!], ","

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

      @text_input_row {
        label: "Description"
        name: "submission[description]"
        type: "textarea"
        value: submission.description
        placeholder: "Optional"
      }

      @input_row "How do you feel about this submission", ->
        @radio_buttons "submission[user_rating]", {
          {"good", "I'm proud of it"}
          {"neutral", "I'm neutral about it"}
          {"bad", "I'm not proud of it"}
        }, @submission and Submissions.user_ratings\to_name(@submission.user_rating) or "neutral"

      @text_input_row {
        label: "Tags"
        class: "tags_input"

        placeholder: "Optional"

        sub: "Classify your submission for easy browsing later (10 max). Press enter to add"
        name: "submission[tags]"
        value: tags_str
      }

      div class: "label", "Files"
      div class: "file_uploader" -- rendered via react

      div class: "button_row", ->
        button class: "button", ->
          if @submission
            text "Save"
          else
            text "Submit"

        if @submission
          text " or "
          a href: @url_for(@submission), "Return to submission"

  streak_picker: =>
    return unless @submittable_streaks
    submit_date = @unit_date or date true

    if #@submittable_streaks == 1
      streak = @submittable_streaks[1]
      p class: "submit_banner", ->
        text "Submitting to #{streak.title}, #{streak\interval_noun false} ##{streak\unit_number_for_date(submit_date)}."
      input type: "hidden", name: "submit_to[#{streak.id}]", value: "on"
      return

    selected = if @params.streak_id
      { [@params.streak_id]: true }
    else
      {}

    @input_row "Submit to", ->
      opts = for s in *@submittable_streaks
        unit_num = "#{s\interval_noun false} ##{s\unit_number_for_date(submit_date)}"
        {tostring(s.id), s.title, unit_num}

      @checkboxes "submit_to", opts, selected

