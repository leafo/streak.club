
class UserProfile extends require "widgets.base"
  @needs: {"user"}

  inner_content: =>
    h2 @user\name_for_display!
    p "Profile"
