
db = require "lapis.db"
import assert_error from require "lapis.application"
import with_params from require "lapis.validate"
import build_url from require "lapis.util"

types = require "lapis.validate.types"
shapes = require "helpers.shapes"

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

with_csrf = (fn) ->
  import assert_csrf from require "helpers.csrf"
  (...) =>
    assert_csrf @
    fn @, ...

assert_timezone = (tz) ->
  assert_error tz, "missing timezone"
  assert_error type(tz) == "string", "missing timezone"
  res = unpack db.select "* from pg_timezone_names where name = ?", tz
  assert_error res, "invalid timezone: #{tz}"

assert_page = with_params {
  {"page", shapes.page_number}
}, (params) =>
  @page = params.page
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
  assert_error @params.date\match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$"), "invalid date"

  parsed_date = date @params.date
  assert_error @params.date == parsed_date\fmt("%Y-%m-%d"), "date mismatch"

  @unit_date = parsed_date\addhours -@streak.hour_offset
  assert_error @streak\date_in_streak(@unit_date), "invalid date"

find_streak = with_params {
  {"id", types.db_id}
}, (params) =>
  import Streaks from require "models"

  @streak = assert_error Streaks\find(params.id), "failed to find streak"
  assert_error @streak\allowed_to_view(@current_user), "not allowed to view streak"
  @streak_user = @streak\has_user @current_user
  true

redirect_for_https = =>
  return false unless config.enable_https

  scheme = if ngx.var.remote_addr == "127.0.0.1"
    @req.headers['x-forwarded-proto'] or @req.scheme
  else
    @req.scheme

  return if scheme == "https"

  if @req.method != "GET"
    @write {
      status: 400
    }, "HTTPS is required for this request"

    return true

  url_opts = {k,v for k,v in pairs @req.parsed_url}
  url_opts.scheme = "https"
  url_opts.port = nil

  @write status: 301, redirect_to: build_url url_opts
  true

{ :not_found, :require_login, :require_admin, :assert_timezone,
  :login_and_return_url, :assert_unit_date, :assert_page, :find_streak,
  :redirect_for_https, :is_crawler, :with_csrf }
