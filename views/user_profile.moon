
SubmissionList = require "widgets.submission_list"

class UserProfile extends require "widgets.base"
  @needs: {"user", "submissions", "streaks"}

  inner_content: =>
    div class: "page_header", ->
      h2 @user\name_for_display!
      h3 ->
        text "A user registered #{@format_timestamp @user.created_at}"
        raw " &middot; "
        text @plural @user.submission_count, "submission", "submissions"


    @render_submissions!
    @render_streaks!

  render_submissions: =>
    return unless next @submissions
    h2 "All submissions"
    widget SubmissionList

  render_streaks: =>
    return unless next @streaks
    h2 "Streaks"
    div class: "streak_list", ->
      for streak in *@streaks
        div class: "streak_row", ->
          h3 ->
            a href: @url_for(streak), streak.title
            text " by "
            a href: @url_for(streak.user), streak.user\name_for_display!

