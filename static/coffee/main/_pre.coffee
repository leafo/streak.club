import dayjs from "main/dayjs"
import $ from "main/jquery"
import {_} from "main/global_libs"

export template_settings = {
  interpolate : /\{\{(.+?)\}\}/g
  escape : /\{\{&(.+?)\}\}/g
  evaluate: /<%([\s\S]+?)%>/g
}

_markdown_deferred = null
export with_markdown = ->
  _markdown_deferred ||= $.ajax {
    url: $("#markdown_src").data "src"
    dataType: "script"
    cache: true
  }

export slugify = (str, opts) ->
  str = str.replace(/\s+/g, "-")

  str = if opts?.for_tags
    str.replace(/[^\w_.-]/g, "")
      .replace(/^[_.-]+/, "")
      .replace(/[_.-]+$/, "")
  else
    str.replace(/[^\w_-]/g, "")

  str.toLowerCase()

export event = (category, action, label, value, interactive=true) ->
  params = ['_trackEvent', category, action, label, value]
  params.push true unless interactive
  try
    if window._gaq
      window._gaq.push params
    else
      console.log "event:", params

export get_template = (name) ->
  _.template $("##{name}_tpl").html(), template_settings

export lazy_template = (obj, name) ->
  (args...) ->
    fn = get_template name
    obj::template = fn
    fn args...

_csrf_token = null
export get_csrf = ->
  _csrf_token ||= $("meta[name='csrf_token']").attr "value"

export with_csrf = (thing={}) ->
  token = { csrf_token: get_csrf() }
  if $.type(thing) == "string"
    sep = if thing.match "?"
      "&"
    else
      "?"

    thing + sep + $.param token
  else
    $.extend thing, token

export has_follow_buttons = (el) ->
  el.dispatch "click", {
    toggle_follow_btn: (btn) =>
      if btn.is ".logged_out"
        return "continue"

      url_key = if btn.is(".following") then "unfollow_url" else "follow_url"
      url = btn.data url_key
      btn.addClass("disabled").prop "disabled", true

      $.post url, with_csrf(), (res) =>
        btn.removeClass("disabled").prop "disabled", false
        if res.success
          btn.toggleClass "following outline_button"
  }

export format_dates = (outer, format="MMMM Do YYYY, h a") ->
  for el in outer.find(".date_format")
    do (el=$ el) ->
      timestamp = el.html()
      el.html(dayjs(timestamp).format format)
        .attr "title", timestamp

# adapted from underscore string: https://github.com/esamattis/underscore.string/blob/master/numberFormat.js
export number_format = (number, dec, dsep=".", tsep=",") ->
  return "" if isNaN(number) || number == null

  number = number.toFixed ~~dec

  parts = number.split '.'
  fnums = parts[0]
  decimals = if parts[1] then dsep + parts[1] else ''

  fnums.replace(/(\d)(?=(?:\d{3})+$)/g, '$1' + tsep) + decimals

export format_bytes = do ->
  thresholds = [
    ["gb", Math.pow 1024, 3]
    ["mb", Math.pow 1024, 2]
    ["kb", 1024]
  ]

  (bytes) ->
    for [label, min] in thresholds
      if bytes >= min
        return "#{number_format bytes / min, 1}#{label}"

    "#{number_format bytes, 1} bytes"

export is_mobile = ->
  /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test navigator.userAgent

