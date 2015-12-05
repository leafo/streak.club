UserHeader = require "widgets.user_header"
SubmissionList = require "widgets.submission_list"


class UserFollowers extends require "widgets.page"
  @needs: {"user", "submissions"}

  @include "widgets.follow_helpers"
  @include "widgets.streak_helpers"

  page_name: "tags"

  inner_content: =>
    widget UserHeader page_name: @page_name
    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    h2 ->
      text "Submissions by #{@user\name_for_display!} tagged "
      span class: "tag", "#{@params.tag_slug}"

    unless next @submissions
      p class: "empty_message", "There are no tagged submissions"
      return

    widget SubmissionList {
      hide_hidden: true
    }

