import escape, unescape, from_json from require "lapis.util"
config = require("lapis.config").get!

{get_session: load_session} = require "lapis.session"

REFERRER_COOKIE = "sc:rr:r"
LANDING_COOKIE = "sc:rr:l"

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

-- set the register & landing referrer when we're just inside of nginx and not lapis
set_register_referrer_nginx = ->
  existing = ngx.var["cookie_#{escape LANDING_COOKIE}"]
  return nil, "already set" if existing

  return nil, "non-get" unless ngx.var.request_method == "GET"

  session = get_session!
  if session and session.user
    return nil, "logged in"

  cookies_set = 0

  for cookie_name, value in pairs {
    [LANDING_COOKIE]: ngx.var.request_uri
    [REFERRER_COOKIE]: ngx.var.http_referer
  }
    continue unless type(value) == "string"
    continue if value == ""
    continue if ngx.var["cookie_#{escape cookie_name}"]

    value = value\sub 1, 200

    cookie = "#{escape cookie_name}=#{escape value}; Path=/;"
    cookie ..= "; Secure" if config.enable_https
    append_cookie cookie
    cookies_set += 1

  cookies_set > 0

-- remove the cookies
unset_register_referrer = ->
  date = require "date"
  local expires
  for c in *{REFERRER_COOKIE, LANDING_COOKIE}
    if existing = ngx.var["cookie_#{escape c}"]
      expires or= date(0)\adddays(365)\fmt "${http}"

      cookie = "#{escape c}=; Path=/; Expires=#{expires}"
      cookie ..= "; Secure" if config.enable_https
      append_cookie cookie

{:set_register_referrer_nginx, :unset_register_referrer, :REFERRER_COOKIE, :LANDING_COOKIE}
