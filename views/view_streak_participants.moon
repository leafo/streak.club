
StreakHeader = require "widgets.streak_header"

class ViewStreakParticipants extends require "widgets.base"
  @needs: {"streak"}

  page_name: "participants"

  inner_content: =>
    widget StreakHeader page_name: @page_name
    text "show user list..."
