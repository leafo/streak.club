
UserHeader = require "widgets.user_header"
StreakList = require "widgets.streak_list"

class UserStreaksHosted extends require "widgets.page"
  @needs: {"streaks", "pager", "page"}
  @include "widgets.pagination_helpers"

  page_name: "streaks_hosted"
  column_content: =>
    widget UserHeader page_name: @page_name
    widget StreakList

