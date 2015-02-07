
SubmissionList = require "widgets.submission_list"

class ViewSubmission extends require "widgets.base"
  @needs: {"submission", "streaks"}
  @include "widgets.twitter_card_helpers"
  @include "widgets.streak_helpers"

  inner_content: =>
    @content_for "meta_tags", ->
      @twitter_card_for_submission @submission

    if @submission\allowed_to_edit @current_user
      div class: "owner_tools", ->
        a href: @url_for("edit_submission", id: @submission.id), "Edit submission"
        raw " &middot; "
        a href: @url_for("delete_submission", id: @submission.id), "Delete submission"

    div class: "submission_column", ->
      widget SubmissionList submissions: { @submission }, show_user: true, show_comments: true

    if next @streaks
      div class: "streaks_column", ->
        if #@streaks == 1
          h2 "Streak"
        else
          h2 "Streaks"

        for streak in *@streaks
          @render_streak_row streak

