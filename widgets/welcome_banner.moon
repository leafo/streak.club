
class WelcomeBanner extends require "widgets.base"
  inner_content: =>
    div class: "banner_inner", ->
      h2 "Welcome to Streak Club"
      p "Streak Club is a place for hosting and participating in creative streaks."
      a href: @url_for("index"), class: "button outline_button", "Learn more"
