
import request from require "lapis.spec.server"

_request = (...) -> request ...

-- returns headers for logged in user
log_in_user_session = (user) ->
  config = require("lapis.config").get "test"
  import encode_session from require "lapis.session"

  stub = { session: {} }

  user\write_session stub
  val = escape encode_session stub.session

  "#{config.session_name}=#{val}"

request_as = (user, url, opts={}) ->
  if user
    cookie = log_in_user_session user
    opts.headers or= {}
    if opts.headers.Cookie
      opts.headers.Cookie ..= "; #{cookie}"
    else
      opts.headers.Cookie = cookie

  request_fn = if fn = opts.request_fn
    opts.request_fn = nil
    fn
  else
    _request

  if opts.post and opts.post.csrf_token == nil
    add_csrf opts

  request_fn url, opts


{ request: _request, :request_as }
