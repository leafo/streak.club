
UserHeader = require "widgets.user_header"
UserList = require "widgets.user_list"

class UserFollowing extends require "widgets.page"
  @needs: {"users", "pager", "page"}
  @include "widgets.pagination_helpers"

  page_name: "following"

  column_content: =>
    widget UserHeader page_name: @page_name
    if next @users
      @render_pager!
      widget UserList users: @users
      @render_pager!
    else
      p class: "empty_message", "#{@user\name_for_display!} is not following anyone"


