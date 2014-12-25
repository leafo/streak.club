
import request from require "lapis.spec.server"
import escape from require "lapis.util"

take_screenshots = os.getenv "SCREENSHOT"

local *

_request = (...) ->
  if take_screenshots
    request_with_snap ...
  else
    request ...

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

  -- if opts.post and opts.post.csrf_token == nil
  --   add_csrf opts

  request_fn url, opts

request_with_snap = do
  dir = "spec/screenshots"
  counter = 1
  (url, opts, ...) ->
    out = { request url, opts, ... }

    opts or= {}
    if out[1] == 200 and not opts.post
      if counter == 1
        os.execute "rm #{dir}/*.png"

      import get_current_server from require "lapis.spec.server"
      server = get_current_server!

      host, path = url\match "^https?://([^/]*)(.*)$"
      unless host
        host = "127.0.0.1"
        path = url

      full_url = "http://#{host}:#{server.app_port}#{path}"
      headers = for k,v in pairs opts.headers or {}
        "'--header=#{k}:#{v}'"

      headers = table.concat headers

      cmd = "CutyCapt #{headers} '--url=#{full_url}' '--out=#{dir}/#{counter}.png'"
      assert os.execute cmd

      counter += 1

    unpack out


{ request: _request, :request_as, :request_with_snap }
