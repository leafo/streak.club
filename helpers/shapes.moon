-- supplementary input validation types

types = require "lapis.validate.types"

page_number = (types.one_of({
  types.empty / 1
  types.number / math.floor
  types.string\length(0,5) * types.pattern("^%d+$") / tonumber
}) * types.range(1, 1000))\describe "page number"

timestamp = (trimmed_text * types.pattern("^%d+%-(%d+)%-(%d+)%s+(%d+):(%d+):(%d+)$"))\describe "timestamp (YYYY-MM-DD HH:MM:SS)"
datestamp = (trimmed_text * types.pattern("^%d+%-(%d+)%-(%d+)$"))\describe "date (YYYY-MM-DD)"

setmetatable {
  :page_number
  :timestamp, :datestamp
}, __index: (field) => error "Invalid field for helpers.shapes: #{field}"
