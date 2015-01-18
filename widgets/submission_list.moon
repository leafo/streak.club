import sanitize_html, is_empty_html from require "helpers.html"
import login_and_return_url from require "helpers.app"

SubmissionCommentList = require "widgets.submission_comment_list"

class SubmissionList extends require "widgets.base"
  @needs: {"submissions"}

  base_widget: false

  show_streaks: true
  show_user: false
  show_comments: false

  js_init: =>
    "new S.SubmissionList(#{@widget_selector!});"

  inner_content: =>
    if @show_comments
      @content_for "all_js", ->
        @include_redactor!

    div class: "submission_list", ->
      for submission in *@submissions
        has_title = submission.title
        classes = "submission_row"
        classes ..= " no_title" unless has_title

        div class: classes, ["data-submission_id"]: submission.id, ->
          div class: "user_column", ->
            a class: "user_link", href: @url_for(submission.user), ->
              img src: submission.user\gravatar!
              span class: "user_name", submission.user\name_for_display!

            has_likes = submission.likes_count > 0

            div class: "like_row #{has_likes and "has_likes" or ""}", ->
              classes = "toggle_like_btn"
              classes ..= " liked" if submission.submission_like

              a {
                "data-like_url": @url_for("submission_like", id: submission.id)
                "data-unlike_url": @url_for("submission_unlike", id: submission.id)
                href: @current_user and "#" or login_and_return_url @
                class: classes
              }, ->
                span class: "on_like icon-heart", ["data-tooltip"]: "Unlike submission"

                span class: "on_no_like icon-heart", ["data-tooltip"]: "Like submission"

              text " "
              span class: "like_count", submission.likes_count

          div class: "submission_content", ->
            div class: "submission_header", ->
              div class: "submission_meta", ->
                a {
                  href: @url_for submission
                  "data-tooltip": submission.created_at
                  "#{@relative_timestamp submission.created_at}"
                }

                if submission\allowed_to_edit @current_user
                  a {
                    href: @url_for("edit_submission", id: submission.id)
                    "data-tooltip": "Edit submission"
                    class: "icon-pencil edit_btn"
                  }


              if submission.title
                h3 class: "submission_title", ->
                  a href: @url_for(submission), submission.title

              h4 class: "submission_summary", ->
                if @show_user
                  text "A submission by "
                  a href: @url_for(@user), @user\name_for_display!
                else
                  text "A submission"

                if @show_streaks and submission.streaks and next submission.streaks
                  text " for "
                  num_streaks = #submission.streaks
                  for i, streak in ipairs submission.streaks
                    text " "
                    a href: @url_for(streak), streak.title

                    if submit = submission.streak_submissions and submission.streak_submissions[i]
                      text " "
                      span class: "unit_number", submit\unit_number!


            if submission.description and not is_empty_html submission.description
              div class: "user_formatted", ->
                raw sanitize_html submission.description
            elseif not (submission.uploads and next submission.uploads)
              p class: "empty_message", "This submission is empty"

            @render_uploads submission

            if submission.tags and next submission.tags
              div class: "submission_tags", ->
                for tag in *submission.tags
                  a class: "submission_tag", tag.slug

            if @show_comments
              @render_comments submission

  render_uploads: (submission) =>
    return unless submission.uploads and next submission.uploads
    div class: "submission_uploads", ->
      for upload in *submission.uploads
        continue unless upload\is_image!
        div class: "submission_upload", ->
          a href: @url_for(upload), target: "_blank", ->
            img src: @url_for upload, "600x"

  render_comments: (submission) =>
    div class: "comment_form_outer", ->
      h3 "Leave a commment"
      action = @url_for "submission_new_comment", id: submission.id
      form class: "form comment_form", method: "POST", :action, ->
        @csrf_input!

        div class: "input_wrapper", ->
          textarea name: "comment[body]", placeholder: "Your comment"

        div class: "button_row", ->
          button class: "button", "Leave comment"

    div class: "submission_comment_list", ->
      return unless submission.comments and next submission.comments
      widget SubmissionCommentList comments: submission.comments

    @js_template "comment_editor", ->
      div class: "comment_editor", ->
        action = @url_for("edit_comment", id: "XXX")\gsub "XXX", "{{ id }}"
        form class: "form edit_comment_form", method: "POST", :action, ->
          @csrf_input!
          div class: "input_wrapper", ->
            textarea name: "comment[body]", placeholder: "Your comment", ->
              raw "{{& body }}"

          div class: "button_row", ->
            button class: "button", "Update comment"
            text " or "
            a class: "cancel_edit_btn", href: "", "Cancel"

