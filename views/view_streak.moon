
class ViewStreak extends require "widgets.base"
  @needs: {"streak"}

  inner_content: =>
    h2 @streak.title
    h3 @streak.short_description

    form action: "", method: "post", ->
      @csrf_input!
      if @streak_user
        button name: "action", value: "leave_streak", "Leave streak"
      else
        button name: "action", value: "join_streak", "Join streak"

