
import sanitize_html, sanitize_style from require "web_sanitize"

url_value = (value) ->
  value and (value\match("^https?://") or value\match("^//")) and true

whitelist = require "web_sanitize.whitelist"
whitelist.tags.iframe = {
  width: true
  height: true
  frameborder: true
  allowfullscreen: true
  scrolling: true
  src: url_value
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

decode_html_entities = do
  entities = {
    amp: '&'
    nbsp: " "
    gt: '>'
    lt: '<'
    quot: '"'
    apos: "'"
    mdash: "—"
    rsquo: '’'
    trade: '™'
    "#x27": "'"
  }

  (str) ->
    (str\gsub '&(.-);', (tag) ->
      if entities[tag]
        entities[tag]
      elseif chr = tag\match "#(%d+)"
        chr = tonumber chr
        if chr >= 32 and chr <= 127
          string.char chr
        else
          "" -- nothing for now
      -- elseif chr = tag\match "#[xX]([%da-fA-F]+)"
      --   utf8.char tonumber chr, 16
      -- ^ this is super crappy because we don't have unicode library
      else
        '&'..tag..';')

convert_links = (html) ->
  import replace_html from require "web_sanitize.query.scan_html"
  replace_html(
    html
    (stack) ->
      node = stack\current!
      if node.type == "text_node" and not stack\is("a *, a")
        node\replace_outer_html node\outer_html!\gsub "(https?://[^ <\"']+)", "<a href=\"%1\">%1</a>"
    text_nodes: true
  )

import Extractor from require "web_sanitize.html"

extract_text = Extractor { printable: true }

{ :sanitize_style, :sanitize_html, :is_empty_html, :decode_html_entities, :convert_links, :extract_text }
