import dayjs from "main/dayjs"
import $ from "main/jquery"
import {_} from "main/global_libs"

export default S = {
  template_settings: {
    interpolate : /\{\{(.+?)\}\}/g
    escape : /\{\{&(.+?)\}\}/g
    evaluate: /<%([\s\S]+?)%>/g
  }

  with_markdown: ->
    S._markdown_deferred ||= $.ajax {
      url: $("#markdown_src").data "src"
      dataType: "script"
      cache: true
    }

  slugify: (str, opts) ->
    str = str.replace(/\s+/g, "-")

    str = if opts?.for_tags
      str.replace(/[^\w_.-]/g, "")
        .replace(/^[_.-]+/, "")
        .replace(/[_.-]+$/, "")
    else
      str.replace(/[^\w_-]/g, "")

    str.toLowerCase()

  event: (category, action, label, value, interactive=true) ->
    params = ['_trackEvent', category, action, label, value]
    params.push true unless interactive
    try
      if window._gaq
        window._gaq.push params
      else
        console.log "event:", params

  get_template: (name) ->
    _.template $("##{name}_tpl").html(), S.template_settings

  lazy_template: (obj, name) ->
    (args...) ->
      fn = S.get_template name
      obj::template = fn
      fn args...

  get_csrf: ->
    @_csrf_token ||= $("meta[name='csrf_token']").attr "value"

  with_csrf: (thing={}) ->
    token = csrf_token: S.get_csrf()
    if $.type(thing) == "string"
      sep = if thing.match "?"
        "&"
      else
        "?"

      thing + sep + $.param token
    else
      $.extend thing, token

  has_follow_buttons: (el) ->
    el.dispatch "click", {
      toggle_follow_btn: (btn) =>
        if btn.is ".logged_out"
          return "continue"

        url_key = if btn.is(".following") then "unfollow_url" else "follow_url"
        url = btn.data url_key
        btn.addClass("disabled").prop "disabled", true

        $.post url, S.with_csrf(), (res) =>
          btn.removeClass("disabled").prop "disabled", false
          if res.success
            btn.toggleClass "following outline_button"
    }

  format_dates: (outer, format="MMMM Do YYYY, h a") ->
    for el in outer.find(".date_format")
      do (el=$ el) ->
        timestamp = el.html()
        el.html(dayjs(timestamp).format format)
          .attr "title", timestamp

  # adapted from underscore string: https://github.com/esamattis/underscore.string/blob/master/numberFormat.js
  number_format: (number, dec, dsep=".", tsep=",") ->
    return "" if isNaN(number) || number == null

    number = number.toFixed ~~dec

    parts = number.split '.'
    fnums = parts[0]
    decimals = if parts[1] then dsep + parts[1] else ''

    fnums.replace(/(\d)(?=(?:\d{3})+$)/g, '$1' + tsep) + decimals

  format_bytes: do ->
    thresholds = [
      ["gb", Math.pow 1024, 3]
      ["mb", Math.pow 1024, 2]
      ["kb", 1024]
    ]

    (bytes) ->
      for [label, min] in thresholds
        if bytes >= min
          return "#{S.number_format bytes / min, 1}#{label}"

      "#{S.number_format bytes, 1} bytes"

  is_mobile: =>
    /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test navigator.userAgent
}


