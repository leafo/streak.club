import sanitize_html, is_empty_html, convert_links from require "helpers.html"
import login_and_return_url from require "helpers.app"
import to_json from require "lapis.util"

SubmissionCommenter = require "widgets.submission_commenter"
SubmissionLiker = require "widgets.submission_liker"
SubmissionListAudioFile = require "widgets.submission_list_audio_file"
SubmissionListVideoFile = require "widgets.submission_list_video_file"

class SubmissionList extends require "widgets.base"
  @needs: {"submissions", "has_more"}

  show_streaks: true
  show_user: false
  show_comments: false
  hide_hidden: false

  @es_module: [[
    import {SubmissionList} from "main/submission_list"
    new SubmissionList(widget_selector, widget_params)
  ]]

  js_init: =>
    super {
      page: @page or 1
    }

  inner_content: =>
    total = @render_submissions!
    if total == 0
      p class: "empty_message", "Nothing to show"

    if total > 0 and @has_more
      div class: "submission_loader list_loader", ->
        text "Loading more"

    div class: "comment_nag_drop"

  render_submissions: =>
    count = 0
    for submission in *@submissions
      hidden, would_hide = if @hide_hidden
        submission\is_hidden_from @current_user

      continue if hidden
      count += 1

      user = submission\get_user!
      suspended = user\display_as_suspended @current_user

      late_submit = false
      if submits = submission.streak_submissions
        for submit in *submits
          if submit.late_submit
            late_submit = true
            break

      div {
        class: "submission_row"
        ["data-submission_id"]: submission.id
      }, ->
        div class: "user_column", ->

          if suspended
            div class: "user_link", ->
              img src: user\gravatar nil, true
              em "Suspended account"
          else
            a {
              class: "user_link"
              href: @url_for user
            }, ->
              img "data-lazy_src": user\gravatar!, width: 80, height: 80
              span class: "user_name", user\name_for_display!

            if user\is_suspended! and @current_user and @current_user\is_admin!
              strong " suspended"

            widget SubmissionLiker @flow("submission")\like_props(
              submission, submission.submission_like
            )

          @submission_admin_panel submission

        div class: "submission_content", tabindex: "-1", ->
          div class: "submission_header", ->
            if submission.title and not suspended
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

          if suspended
            div class: "submission_inside_content truncated", ->
              p class: "empty_message", "This account has been suspended for violating our terms of service or spamming"
          else
            div class: "submission_inside_content truncated", ->
              if submission.description and not is_empty_html submission.description
                div class: "user_formatted", ->
                  raw sanitize_html convert_links submission.description
              elseif not (submission.uploads and next submission.uploads)
                p class: "empty_message", "This submission is empty"

              @render_uploads submission, count

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

    count

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

  render_uploads: (submission, count) =>
    return unless submission.uploads and next submission.uploads
    lazy_image = count != 1

    div class: "submission_uploads", ->
      for upload in *submission.uploads
        if upload\is_image!
          width, height, thumb = upload\thumbnail_dimensions!
          image_src = @url_for upload, thumb

          div class: "submission_image", ->
            a href: @url_for(upload), target: "_blank", ->
              img {
                :width
                :height
                style: "max-width: #{width}px; max-height: #{height}px;"
                src: if not lazy_image then image_src
                "data-lazy_src": if lazy_image then image_src
              }
        elseif upload\is_video! and upload\valid_for_embed!
          widget SubmissionListVideoFile {
            download_url: @url_for "prepare_download", id: upload.id
            upload: {
              id: upload.id
              filename: upload.filename
              size: upload.size
              width: upload.width, height: upload.height
            }
          }
        elseif upload\is_audio!
          widget SubmissionListAudioFile {
            audio_url: @url_for "prepare_play_audio", id: upload.id
            download_url: @url_for "prepare_download", id: upload.id
            submission: {
              id: submission.id
              user_name: submission\get_user!\name_for_display!
              user_url: @url_for submission\get_user!
            }
            upload: {
              id: upload.id
              filename: upload.filename
              size:  upload.size
            }
          }
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

