import Flow from require "lapis.flow"

types = require "lapis.validate.types"

class UserFlow extends Flow
  expose_assigns: true

  -- ensusre that return_to goes to a valid URL in the app to prevent phishing
  -- redirects
  load_return_to: =>
    if types.valid_text @params.return_to
      success, _, _, route_name = @app.router\match @params.return_to
      if success
        @return_to = @params.return_to
        @return_to_route_name = route_name

