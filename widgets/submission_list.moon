import sanitize_html, is_empty_html, convert_links from require "helpers.html"
import login_and_return_url from require "helpers.app"
import to_json from require "lapis.util"

SubmissionCommenter = require "widgets.submission_commenter"
MarkdownEditor = require "widgets.markdown_editor"

class SubmissionList extends require "widgets.base"
  @needs: {"submissions", "has_more"}

  show_streaks: true
  show_user: false
  show_comments: false
  hide_hidden: false

  js_init: =>
    opts = {
      page: @page or 1
    }

    "new S.SubmissionList(#{@widget_selector!}, #{to_json opts});"

  inner_content: =>
    @render_submissions!

    if @has_more
      div class: "submission_loader list_loader", ->
        text "Loading more"

    @templates!

  render_submissions: =>
    for submission in *@submissions
      hidden, would_hide = if @hide_hidden
        submission\is_hidden_from @current_user

      continue if hidden

      has_title = submission.title
      classes = "submission_row"
      classes ..= " no_title" unless has_title

      late_submit = false
      if submits = submission.streak_submissions
        for submit in *submits
          if submit.late_submit
            late_submit = true
            break

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
            a {
              href: @url_for("submission_likes", id: submission.id)
              class: "like_count"
              "data-tooltip": "View who liked"
              submission.likes_count
            }

            @submission_admin_panel submission

        div class: "submission_content", ->
          div class: "submission_header", ->
            if submission.title
              h3 class: "submission_title", ->
                a href: @url_for(submission), submission.title

            submitted_streaks = if @show_streaks and submission.streaks
              current_streak_id = @streak and @streak.id
              submission\visible_streaks_for @current_user, current_streak_id

            h4 class: "submission_summary", ->
              if @show_user
                text "A submission by "
                a href: @url_for(submission.user), submission.user\name_for_display!
              else
                text "A submission"

              if submitted_streaks and next submitted_streaks
                text " for "
                num_streaks = #submitted_streaks
                for i, streak in ipairs submitted_streaks
                  text " "
                  span class: "streak_title_group", ->
                    a href: @url_for(streak), streak.title

                    if streak\has_end!
                      if submit = submission.streak_submissions and submission.streak_submissions[i]
                        text " "
                        span class: "unit_number", submit\unit_number!

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

            if would_hide
              div class: "hidden_notice", ->
                text "This submission is part of a hidden streak but you have
                permission to see it."

          div class: "submission_inside_content truncated", ->
            if submission.description and not is_empty_html submission.description
              div class: "user_formatted", ->
                raw sanitize_html convert_links submission.description
            elseif not (submission.uploads and next submission.uploads)
              p class: "empty_message", "This submission is empty"

            @render_uploads submission

          div class: "submission_footer", ->
            div class: "footer_inside", ->
              a {
                id: "comments-#{submission.id}"
                href: @url_for(submission) .. "#comments-#{submission.id}"
                class: "comments_toggle_btn #{@show_comments and "locked" or ""}"
                "data-comments_url": @url_for("submission_comments", id: submission.id)
                "data-template": "{{ count }} comment{{ count == 1 ? '' : 's' }}"
                "data-count": submission.comments_count
              }, ->
                text @plural submission.comments_count, "comment", "comments"

            if submission.tags and next(submission.tags) or late_submit
              div class: "submission_tags", ->
                if late_submit
                  a class: "submission_tag late_submit_tag", ["data-tooltip"]: "Submission added past the deadline", "late-submit"
                for tag in *submission.tags
                  a {
                    class: "submission_tag"
                    href: @url_for "user_tag", slug: submission.user.slug, tag_slug: tag.slug
                    tag.slug
                  }

          if @show_comments
            @render_comments submission


  submission_admin_panel: (submission) =>
    return unless @current_user and @current_user\is_admin!
    div class: "submission_admin", ->
      a href: @admin_url_for(submission), "Admin"

      form {
        method: "post"
        action: @url_for("admin.feature_submission", id: submission.id)
        target: "_blank"
      }, ->
        @csrf_input!
        if submission.featured_submission
          button name:"action", value: "delete", "Unfeature"
        else
          button name:"action", value: "create", "Feature"

  templates: =>
    @js_template "comment_editor", ->
      div class: "comment_editor", ->
        action = @url_for("edit_comment", id: "XXX")\gsub "XXX", "{{ id }}"
        form class: "form edit_comment_form", method: "POST", :action, ->
          @csrf_input!
          div class: "input_wrapper", ->
            widget MarkdownEditor {
              name: "comment[body]"
              placeholder: "Your comment"
              required: true
              js_init: false
              value: ->
                raw "{{& body }}"
            }

          div class: "button_row", ->
            button class: "button", "Update comment"
            text " or "
            a class: "cancel_edit_btn", href: "", "Cancel"

  render_uploads: (submission) =>
    return unless submission.uploads and next submission.uploads
    div class: "submission_uploads", ->
      for upload in *submission.uploads
        if upload\is_image!
          div class: "submission_image", ->
            a href: @url_for(upload), target: "_blank", ->
              img src: @url_for upload, "600x"
        elseif upload\is_audio!
          div class: "submission_audio", ->
            div {
              class: "play_audio_btn"
              ["data-audio_url"]: @url_for "prepare_play_audio", id: upload.id
            }, ->
              img class: "play_icon", src: "/static/images/audio_play.svg"
              img class: "pause_icon", src: "/static/images/audio_pause.svg"

            form {
              class: "download_form"
              action: @url_for "prepare_download", id: upload.id
              method: "post"
            }, ->
              @csrf_input!
              button class: "upload_download button", "Download"

            div class: "truncate_content", ->
              span class: "upload_name", upload.filename
              span class: "upload_size", @filesize_format upload.size

              div class: "audio_progress_outer", ->
                div class: "audio_progress_inner"

        else
          form {
            class: "submission_upload"
            action: @url_for "prepare_download", id: upload.id
            method: "post"
          }, ->
            @csrf_input!
            if upload.downloads_count > 0
              div class: "upload_stats", ->
                text @plural @number_format(upload.downloads_count),
                  "download", "downloads"

            button class: "upload_download button", "Download"
            span class: "upload_name", upload.filename
            span class: "upload_size", @filesize_format upload.size

  render_comments: (submission) =>
    widget SubmissionCommenter {
      submission: @submission
      submission_comments: @submission.comments
      has_more: @submission.has_more_comments
    }

