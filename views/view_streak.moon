
class ViewStreak extends require "widgets.base"
  @needs: {"streak"}

  inner_content: =>
    h2 @streak.title
    h3 @streak.short_description

    form action: "", method: "post", =>
      button name: "action", value: "join_streak", "Join streak"

