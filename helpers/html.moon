
import extract_text, sanitize_html, sanitize_style from require "web_sanitize"

whitelist = require "web_sanitize.whitelist"
whitelist.tags.iframe = {
  width: true
  height: true
  frameborder: true
  allowfullscreen: true
  scrolling: true
  src: true
}

whitelist.tags.del = true
whitelist.tags.a.target = true
whitelist.tags[1].style = (text) -> sanitize_style text

is_empty_html =  (str) ->
  -- has an image, not empty
  return false if str\match "%<[iI][mM][gG]%s"

  -- only whitespace after html tags removed
  out = (str\gsub("%<.-%>", "")\gsub("&nbsp;", ""))
  not not out\find "^%s*$"

{ :sanitize_style, :sanitize_html, :is_empty_html }
