
StreakHeader = require "widgets.streak_header"
UserList = require "widgets.user_list"

class ViewStreakParticipants extends require "widgets.base"
  @needs: {"streak"}
  @include "widgets.pagination_helpers"

  page_name: "participants"

  inner_content: =>
    widget StreakHeader page_name: @page_name

    if @pending_users and next @pending_users
      h3 "Pending participants"

      widget UserList {
        users: @pending_users
        action_area: =>
          form action: "", ->
            button class: "button user_action_btn", "Approve member"
      }

      h3 "Approved participants"

    if next @users
      @render_pager!
      widget UserList users: @users
      @render_pager!
    else
      p class: "empty_message", "There don't appear to be any participants yet"


