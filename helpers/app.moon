
db = require "lapis.db"
import assert_error from require "lapis.application"
import assert_valid from require "lapis.validate"

date = require "date"

not_found = { status: 404, render: "not_found" }

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
  @url_for("user_login") .. "?" .. encode_query_string {
    return_to: @build_url url
  }

-- unit_date is in UTC
assert_unit_date = =>
  y, m, d = assert_error @params.date\match("%d+-%d+-%d+"), "invalid date"
  @unit_date = date(@params.date)\addhours -@streak.hour_offset
  assert_error @streak\date_in_streak(@unit_date), "invalid date"

parse_filters = (str, valid_keys) ->
  has_invalid = false
  out = {}
  for key, val in str\gmatch "(%w+)%-([%w-,]+)"
    valid_values = valid_keys[key]

    unless valid_values and (valid_values == true or valid_values[val])
      has_invalid = true
      continue

    out[key] = val

  out, has_invalid


{ :not_found, :require_login, :require_admin, :assert_timezone,
  :login_and_return_url, :assert_unit_date, :assert_page, :parse_filters }
