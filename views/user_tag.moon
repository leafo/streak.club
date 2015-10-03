UserHeader = require "widgets.user_header"
SubmissionList = require "widgets.submission_list"


class UserFollowers extends require "widgets.page"
  @needs: {"user", "submissions"}

  @include "widgets.follow_helpers"
  @include "widgets.streak_helpers"

  page_name: "tags"

  column_content: =>
    widget UserHeader page_name: @page_name

    h2 ->
      text "Submissions by #{@user\name_for_display!} tagged "
      span class: "tag", "#{@params.tag_slug}"

    unless next @submissions
      p class: "empty_message", "There are no tagged submissions"
      return

    widget SubmissionList {
      hide_hidden: true
    }

