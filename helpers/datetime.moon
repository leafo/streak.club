
date = require "date"

import time_ago_in_words, date_diff from require "lapis.util"

-- takes a db date as input, returns
-- [1] human-readable absolute date
-- [2] human-readable relative date

format_date = (input) ->
  moment = date input
  now = date true

  rel = time_ago_in_words input, 1, ""
  if moment > now
    rel = "In #{rel}"
  else
    rel = "#{rel} ago"

  abs = moment\fmt "%d %B %Y @ %H:%M"

  return abs, rel

date_units = {
  "years"
  "days"
  "hours"
  "minutes"
  "seconds"
}

format_date_short = (input) ->
  d = date input
  now = date true

  if now < d
    now, d = now, d

  diff = date_diff now, d

  for unit in *date_units
    if val = diff[unit]
      return "#{val}#{unit\sub 1,1}"

  "recently"

{ :format_date, :format_date_short }

