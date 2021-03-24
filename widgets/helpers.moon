
date = require "date"
import time_ago_in_words from require "lapis.util"

-- TODO: move all common widget helpers into here

truncate = do
  import C, Cmt from require "lpeg"
  import printable_character, whitespace from require "lapis.util.utf8"

  nonwhitespace = 1 - whitespace
  trim_right = C (whitespace^0 * nonwhitespace^1)^0

  remaining = 0
  truncator = C Cmt(printable_character, (pos) ->
    remaining -= 1
    remaining >= 0
  )^0

  (str, len) ->
    remaining = assert len, "missing length"

    if #str < remaining
      return str

    trim_right\match truncator\match(str) or ""

class Helpers
  truncate: (str, len=30, tail="...") =>
    out = truncate str, len
    if out != str and tail
      out .. tail
    else
      out

  format_number: (num) =>
    tostring(num)\reverse!\gsub("(...)", "%1,")\match("^(.-),?$")\reverse!

  format_duration: do
    limits = {
      {"y", 60*60*24*365}
      {"w", 60*60*24*7}
      {"d", 60*60*24}
      {"h", 60*60}
      {"m", 60}
      {"s", 1}
      {"ms", 1/1000}
    }

    (seconds) =>
      for {label, min} in *limits
        if seconds > min or min < 1
          formatted = "%0.2f"\format(seconds / min)\gsub "%.0+$", ""
          return "#{formatted} #{label}"

      "#{seconds} s"
