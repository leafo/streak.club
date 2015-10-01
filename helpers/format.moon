
date = require "date"
import time_ago_in_words, date_diff from require "lapis.util"

format_date = (d) ->
  moment = date d
  now = date true

  diff, suffix = if moment < now
    date_diff(now, moment), "ago"
  else
    date_diff(moment, now), "from now"

  time_ago_in_words diff, 1, suffix

{ :format_date }
