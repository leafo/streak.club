
class WelcomeBanner extends require "widgets.base"
  base_widget: false

  inner_content: =>
    h2 "Welcome to Streak Club"
    p "Streak Club is a place for hosting and participating in creative streaks."
    a href: @url_for("index"), class: "button outline_button", "Learn more"
