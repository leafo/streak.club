
class SubmissionList extends require "widgets.base"
  @needs: {"submissions"}

  show_streaks: true

  inner_content: =>
    div class: "submission_list", ->
      for submission in *@submissions
        div class: "submission_row", ->
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
