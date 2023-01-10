-- supplementary input validation types

types = require "lapis.validate.types"

page_number = (types.one_of({
  types.empty / 1
  types.number / math.floor
  types.string\length(0,5) * types.pattern("^%d+$") / tonumber
}) * types.range(1, 1000))\describe "page number"

timestamp = (types.trimmed_text * types.pattern("^%d+%-(%d+)%-(%d+)%s+(%d+):(%d+):(%d+)$"))\describe "timestamp (YYYY-MM-DD HH:MM:SS)"
datestamp = (types.trimmed_text * types.pattern("^%d+%-(%d+)%-(%d+)$"))\describe "date (YYYY-MM-DD)"

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


setmetatable {
  :page_number
  :email
  :timestamp, :datestamp
  :url
  :twitter_username
}, __index: (field) => error "Invalid field for helpers.shapes: #{field}"
