
SubmissionList = require "widgets.submission_list"
StreakHeader = require "widgets.streak_header"
UserHeader = require "widgets.user_header"

date = require "date"

class ViewSubmission extends require "widgets.page"
  @needs: {"submission", "streak_submissions", "other_submissions"}
  @include "widgets.twitter_card_helpers"
  @include "widgets.streak_helpers"

  responsive: true

  inner_content: =>
    if #@streak_submissions == 1
      widget StreakHeader {
        page_name: "submission"
        streak: @streak_submissions[1]\get_streak!
        insert_tab: =>
          @page_tab "Submission", "submission", @url_for(@submission)
      }
    else
      widget UserHeader {
        page_name: "submission"
        insert_tab: =>
          @page_tab "Submission", "submission", @url_for(@submission)
      }

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    @content_for "meta_tags", ->
      @twitter_card_for_submission @submission

    @admin_tools!

    if @submission\allowed_to_edit @current_user
      div class: "owner_tools", ->
        a href: @url_for("edit_submission", id: @submission.id), "Edit submission"
        text " "
        a href: @url_for("delete_submission", id: @submission.id), "Delete submission"
        text " "
        a href: @url_for("submission_streaks", id: @submission.id), "Edit streaks"
    else
      for submit in *@streak_submissions
        if submit\allowed_to_moderate @current_user
          div class: "moderator_tools", ->
            a href: @url_for("submission_streaks", id: @submission.id), "Manage this submission's streaks"
          break


    div class: "submission_column", ->
      widget SubmissionList {
        submissions: { @submission }
        show_user: true
        show_comments: true
      }

      @render_other_submissions!

    if next @streak_submissions
      div class: "streaks_column", ->
        for submit in *@streak_submissions
          @render_streak_row submit.streak, {
            highlight_date: date(submit.submit_time)
            show_user_streak: false
            user_id: @user.id
          }

  admin_tools: =>
    return unless @current_user and @current_user\is_admin!
    div class: "admin_tools", ->
      a href: @admin_url_for(@submission), "Admin"

      div ->
        strong "Feature"

      form method: "post", action: @url_for("admin.feature_submission", id: @submission.id), ->
        feature = @submission\get_featured_submission!
        @csrf_input!
        if feature
          button name:"action", value: "delete", "Unfeature"
        else
          button name:"action", value: "create", "Feature"

      div ->
        strong "Tweet builder"

      textarea readonly: true, ->
        text @submission\meta_title true
        text " "
        text @build_url @url_for @submission

        hashes = ["##{s.streak.twitter_hash}" for s in *@streak_submissions when s.streak.twitter_hash]

        if next hashes
          text " "
          text table.concat hashes, " "


  render_other_submissions: =>
    return unless @other_submissions and next @other_submissions
    div class: "other_submissions", ->
      h2 ->
        user = @submission\get_user!
        streak = @streak_submissions[1]\get_streak!

        text "More submissions by "
        a href: @url_for(user), user\name_for_display!
        text " for "
        a href: @url_for(streak), streak.title



      widget SubmissionList {
        submissions: @other_submissions
        show_user: true
      }
