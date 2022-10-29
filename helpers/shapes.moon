-- these are shapes suitable for input validation

import types from require "tableshape"
import printable_character, trim from require "lapis.util.utf8"

import Cs, P from require "lpeg"

empty = types.one_of {
  types.nil
  types.pattern("^%s*$") / nil
  types.literal(require("cjson").null) / nil
  if ngx
    types.literal(ngx.null) / nil
}, describe: -> "empty"

valid_text = types.string / (Cs (printable_character + P(1) / "")^0 * -1)\match

trimmed_text = valid_text / trim\match * types.custom(
  (v) -> v and v != "", "expected text"
  describe: -> "not empty"
)

db_id = types.one_of({
  types.number * types.custom (v) -> v == math.floor(v)
  types.string\length(0,18) / trim\match * types.pattern("^%d+$") / tonumber
}, describe: -> "integer") * types.range(0, 2147483647)\describe "database id"


timestamp = (trimmed_text * types.pattern("^%d+%-(%d+)%-(%d+)%s+(%d+):(%d+):(%d+)$"))\describe "timestamp (YYYY-MM-DD HH:MM:SS)"

datestamp = (trimmed_text * types.pattern("^%d+%-(%d+)%-(%d+)$"))\describe "date (YYYY-MM-DD)"

{
  :empty
  :valid_text, :trimmed_text
  :db_id
  :timestamp, :datestamp
}
