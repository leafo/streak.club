
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

