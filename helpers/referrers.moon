import escape, unescape, from_json from require "lapis.util"
config = require("lapis.config").get!

{get_session: load_session} = require "lapis.session"

REFERRER_COOKIE = "ref:register:referrer"
LANDING_COOKIE = "ref:register:landing"

-- read the session out of the cookie
-- it is cached in the context for multiple reads
get_session = ->
  current = ngx.ctx.current_session
  if current != nil
    return current

  c = ngx.var["cookie_#{config.session_name}"]

  session = c and load_session {
    cookies: {
      [config.session_name]: unescape c
    }
  }, config.session_secret

  ngx.ctx.current_session = session or false
  session

append_cookie = (cookie) ->
  cookies = ngx.header["Set-Cookie"] or {}
  cookies = { cookies } if type(cookies) == "string"
  table.insert cookies, cookie

  ngx.header["Set-Cookie"] = cookies

-- set the register referrer when we're just inside of nginx and not lapis
set_register_referrer_nginx = ->
  existing = ngx.var["cookie_#{escape REFERRER_COOKIE}"]
  return nil, "already set" if existing

  return nil, "non-get" unless ngx.var.request_method == "GET"

  referrer = ngx.var.http_referer
  return unless type(referrer) == "string"
  return nil, "no referrer" if referrer == ""

  session = get_session!
  if session and session.user
    return nil, "logged in"

  referrer = referrer\sub 1, 200

  cookie = "#{escape REFERRER_COOKIE}=#{escape referrer}; Path=/;"
  cookie ..= "; Secure" if config.enable_https

  append_cookie cookie

  true

-- remove the cookies
unset_register_referrer = ->
  date = require "date"
  local expires
  for c in *{REFERRER_COOKIE}
    if existing = ngx.var["cookie_#{escape c}"]
      expires or= date(0)\adddays(365)\fmt "${http}"

      cookie = "#{escape c}=; Path=/; Expires=#{expires}"
      cookie ..= "; Secure" if config.enable_https
      append_cookie cookie

{:set_register_referrer_nginx, :unset_register_referrer, :REFERRER_COOKIE, :LANDING_COOKIE}
