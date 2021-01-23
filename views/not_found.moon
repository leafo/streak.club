
class NotFound extends require "widgets.page"
  column_content: =>
    h2 "404: Not found"

    switch @route_name
      when "user_profile"
        if @user
          if @user\is_suspended!
            p ->
              text "This account has been suspended"
              if @user\is_spam!
                text " for spamming"
          else
            scan = @user\get_spam_scan!
            if scan and scan\needs_review!
              p ->
                text "This account is under review before it can be viewed by a logged out user. Log in to view this page."

      when "view_streak"
        if @streak
          user = @streak\get_user!
          if user\is_suspended!
            p ->
              text "The account that created this streak has been suspended"
              if user\is_spam!
                text " for spamming"

    if @current_user and @current_user\is_admin!
      h3 "Admin"
      pre require("moon").dump @errors


