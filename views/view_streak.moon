
class ViewStreak extends require "widgets.base"
  @needs: {"streak"}

  inner_content: =>
    h2 @streak.title
    h3 @streak.short_description



