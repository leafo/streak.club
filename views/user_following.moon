
UserHeader = require "widgets.user_header"
UserList = require "widgets.user_list"

class UserFollowing extends require "widgets.page"
  @needs: {"users", "pager", "page"}
  @include "widgets.pagination_helpers"

  page_name: "following"

  inner_content: =>
    widget UserHeader page_name: @page_name
    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    if next @users
      @render_pager!
      widget UserList users: @users
      @render_pager!
    else
      div class: "inner_column", ->
        p class: "empty_message", "#{@user\name_for_display!} is not following anyone"


