
db = require "lapis.db"
import assert_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import build_url from require "lapis.util"

config = require("lapis.config").get!

date = require "date"

not_found = { status: 404, render: "not_found" }

is_crawler = ->
  ngx and ngx.var.is_crawler == "1"

require_login = (fn) ->
  =>
    if @current_user
      fn @
    else
      redirect_to: @url_for"user_login"

require_admin = (fn) ->
  =>
    if @current_user and @current_user\is_admin!
      fn @
    else
      redirect_to: @url_for"index"

assert_timezone = (tz) ->
  assert_error tz, "missing timezone"
  assert_error type(tz) == "string", "missing timezone"
  res = unpack db.select "* from pg_timezone_names where name = ?", tz
  assert_error res, "invalid timezone: #{tz}"

assert_page = =>
  assert_valid @params, {
    {"page", optional: true, is_integer: true}
  }

  @page = math.max 1, tonumber(@params.page) or 1
  @page

login_and_return_url = (url=ngx.var.request_uri) =>
  import encode_query_string from require "lapis.util"

  if @current_user
    url
  elseif is_crawler!
    -- simple login url so we aren't generating excess URLs for bots to crawl
    @url_for("user_login")
  else
    @url_for("user_login") .. "?" .. encode_query_string {
      return_to: url
    }

-- unit_date is in UTC
assert_unit_date = =>
  y, m, d = assert_error @params.date\match("%d+-%d+-%d+"), "invalid date"
  @unit_date = date(@params.date)\addhours -@streak.hour_offset
  assert_error @streak\date_in_streak(@unit_date), "invalid date"


find_streak = =>
  assert_valid @params, {
    {"id", is_integer: true}
  }

  import Streaks from require "models"

  @streak = assert_error Streaks\find(@params.id), "failed to find streak"
  assert_error @streak\allowed_to_view(@current_user), "not allowed to view streak"
  @streak_user = @streak\has_user @current_user
  true

ensure_https = (fn) ->
  =>
    scheme = if ngx.var.remote_addr == "127.0.0.1"
      @req.headers['x-forwarded-proto'] or @req.scheme
    else
      @req.scheme

    if scheme == "http" and config.enable_https
      url_opts = {k,v for k,v in pairs @req.parsed_url}
      url_opts.scheme = "https"
      url_opts.port = nil

      return status: 301, redirect_to: build_url url_opts

    fn @

{ :not_found, :require_login, :require_admin, :assert_timezone,
  :login_and_return_url, :assert_unit_date, :assert_page, :find_streak,
  :ensure_https, :is_crawler }
