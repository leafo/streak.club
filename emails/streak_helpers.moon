
class EmailStreakHelpers
  leave_streak_message: =>
    p style: "font-size: small; color: #666", ->
      text "If you want to leave the streak you can find the 'leave streak' button on the "
      a style: "color: #666", href: @url_for(@streak), "streak's page"
      text "."

