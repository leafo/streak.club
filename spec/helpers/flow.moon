import Application from require "lapis.application"
import capture_errors from require "lapis.application"
import mock_action from require "lapis.spec.request"

return_errors = (fn) ->
  capture_errors fn, (req) ->
    nil, req.errors

assert = require "luassert"

router = ->
  import Router from require "lapis.router"
  r = Router!
  r.default_route = => false

  -- TODO: pull in routes faster
  -- routes = require "misc.routes"
  -- for k, v in pairs routes
  --   continue unless type(k) == "string"
  --   r\add_route { [k]: v }, (...) -> true

  router = -> r
  r

in_request = (opts, run) ->
  class S extends Application
    Request: require "helpers.request"

    -- just run the / action directly with no routing or error capturing
    dispatch: (req, res) =>
      r = @.Request @, req, res
      @wrap_handler(@["/"]) {}, req.parsed_url.path, "index", r
      @render_request r

  assert mock_action S, "/", opts, return_errors run

{:return_errors, :in_request}

