import Flow from require "lapis.flow"

class UserFlow extends Flow
  expose_assigns: true

  load_return_to: =>
    if @params.return_to
      assert type(@params.return_to) == "string"
      success, _, _, route_name = @app.router\match @params.return_to
      if success
        @return_to = @params.return_to
        @return_to_route_name = route_name

