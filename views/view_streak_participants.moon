
StreakHeader = require "widgets.streak_header"
UserList = require "widgets.user_list"

class ViewStreakParticipants extends require "widgets.base"
  @needs: {"streak"}
  @include "widgets.pagination_helpers"

  page_name: "participants"

  inner_content: =>
    widget StreakHeader page_name: @page_name
    if next @users
      @render_pager!
      widget UserList users: @users
      @render_pager!
    else
      p class: "empty_message", "There don't appear to be any participants yet"
