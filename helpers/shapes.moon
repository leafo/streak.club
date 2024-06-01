-- supplementary input validation types

import is_empty_html from require "helpers.html"

types = require "lapis.validate.types"

integer = types.one_of({
  types.number / math.floor
  types.string\length(0,10) * types.pattern("^%d+$") / tonumber
})\describe "integer"

page_number = (types.one_of({
  types.empty / 1
  types.number / math.floor
  types.string\length(0,5) * types.pattern("^%d+$") / tonumber
}) * types.range(1, 1000))\describe "page number"

timestamp = (types.trimmed_text * types.pattern("^%d+%-(%d+)%-(%d+)%s+(%d+):(%d+):(%d+)$"))\describe "timestamp (YYYY-MM-DD HH:MM:SS)"
datestamp = (types.trimmed_text * types.pattern("^%d%d%d%d%-%d%d?%-%d%d?$"))\describe "date (YYYY-MM-DD)"

email = types.limited_text(256) * types.pattern("^[^@%s]+@[^@%s%.]+%.[^@%s]+$")\describe "email"

url = (types.limited_text(255) * types.one_of {
  types.pattern "^https?://[^%s]+$"
  types.pattern("^[^%s]+$") / (s) -> "http://#{s}"
})\describe "url"

twitter_username = (types.trimmed_text * types.string\length(1,20) * types.pattern(
  "^@?[_a-zA-Z0-9]+$"
))\describe("twitter usename") / (str) ->
  unless str\match "^@"
    "@#{str}"
  else
    str

twitter_hash = types.all_of({
  types.limited_text(139) / (str) ->
    (str\gsub("%s", "")\gsub("#", ""))
  -types.empty
})\describe "twitter hash"

empty_html = types.custom((s) -> is_empty_html s)\describe("empty html")

timezone = types.all_of({
  types.limited_text(128) / (tz) ->
    db = require "lapis.db"
    (unpack db.select "* from pg_timezone_names where name = ?", tz)
  -types.nil
})\describe("timezone")

map_to_array = (field_name, v_type=types.table) ->
  types.map_of(types.string, v_type) / (t) ->
    return for k,v in pairs t
      item = {r,s for r,s in pairs v}
      item[field_name] = k
      item

to_json_array = types.equivalent({}) / require("cjson").empty_array + types.assert types.table


setmetatable {
  :integer
  :page_number
  :email
  :timestamp, :datestamp
  :url
  :twitter_username, :twitter_hash
  :empty_html
  :timezone
  :map_to_array
  :to_json_array
}, __index: (field) => error "Invalid field for helpers.shapes: #{field}"
