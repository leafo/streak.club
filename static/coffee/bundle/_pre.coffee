
_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g
  evaluate: /<%([\s\S]+?)%>/g
}

window.S = {
  event: (category, action, label, value, interactive=true) ->
    params = ['_trackEvent', category, action, label, value]
    params.push true unless interactive
    try
      if _gaq
        _gaq.push params
      else
        console.log "event:", params

  get_template: (name) ->
    _.template $("##{name}_tpl").html()

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
      thing  + "&" + $.param token
    else
      $.extend thing, token
}

$.fn.dispatch = (event_type, table) ->
  @on event_type, (e) =>
    for key, fn of table
      elm = $(e.target).closest ".#{key}"
      continue unless elm.length
      return false if elm.is ".disabled"

      if elm.is "[data-require-login]"
        return false if I.handle_require_login(elm) == false
      fn elm, e
      return false
    null
  @

_.str.formatBytes = do ->
  thresholds = [
    ["gb", Math.pow 1024, 3]
    ["mb", Math.pow 1024, 2]
    ["kb", 1024]
  ]

  (bytes) ->
    for [label, min] in thresholds
      if bytes >= min
        return "#{_.str.numberFormat bytes / min}#{label}"

    "#{_.str.numberFormat bytes} bytes"
