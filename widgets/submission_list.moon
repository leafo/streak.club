
class SubmissionList extends require "widgets.base"
  @needs: {"submissions"}

  show_streaks: true

  inner_content: =>
    div class: "submission_list", ->
      for submission in *@submissions
        div class: "submission_row", ->
          img src: submission.user\gravatar!
          h3 ->
            a href: @url_for(submission), submission.title

          if @show_streaks
            h4 ->
              text "A submission for"
              num_streaks = #submission.streaks
              for i, streak in ipairs submission.streaks
                text " "
                a href: @url_for(streak), streak.title
                text ", " unless i == num_streaks

          p class: "sub", "Submitted #{@format_timestamp submission.created_at}"
          p submission.description

          @render_uploads submission


  render_uploads: (submission) =>
    return unless submission.uploads and next submission.uploads
    div class: "submission_uploads", ->
      for upload in *submission.uploads
        continue unless upload\is_image!
        div class: "submission_upload", ->
          a href: @url_for(upload), target: "_blank", ->
            img src: @url_for(upload, "400x400")


