import sanitize_html, is_empty_html from require "helpers.html"
import login_and_return_url from require "helpers.app"

class SubmissionList extends require "widgets.base"
  @needs: {"submissions"}

  base_widget: false

  show_streaks: true
  show_user: false

  js_init: =>
    "new S.SubmissionList(#{@widget_selector!});"

  inner_content: =>
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

  render_uploads: (submission) =>
    return unless submission.uploads and next submission.uploads
    div class: "submission_uploads", ->
      for upload in *submission.uploads
        continue unless upload\is_image!
        div class: "submission_upload", ->
          a href: @url_for(upload), target: "_blank", ->
            img src: @url_for upload, "600x"


