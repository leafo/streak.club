
UserHeader = require "widgets.user_header"
StreakList = require "widgets.streak_list"


class UserStreaksHosted extends require "widgets.base"
  @needs: {"streaks", "pager", "page"}
  @include "widgets.pagination_helpers"

  page_name: "streaks_hosted"
  inner_content: =>
    widget UserHeader page_name: @page_name
    widget StreakList

