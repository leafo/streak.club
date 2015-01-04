
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

  redactor: (el, opts={}) =>
    return if window.location.href.match /\bredactor=0\b/
    return unless $.fn.redactor

    opts = $.extend {}, S.default_redactor_opts, opts
    try
      el.redactor opts
    catch e
      S.event "error", "redactor", "invalid_content"
      # attempt to save the page
      el.parent().replaceWith(el).end().val("").redactor opts

  default_redactor_opts: {
    toolbarFixed: false
    buttonSource: true
    buttons: [
      'html'
      'formatting'
      'bold'
      'italic'
      'deleted'
      'unorderedlist'
      'orderedlist'
      'outdent'
      'indent'
      'image'
      'table'
      'link'
      'alignment'
      'horizontalrule'
    ]
    minHeight: 250
  }
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

$.fn.remote_submit = (fn, validate_fn) ->
  click_input = null

  @on "click", "button[name], input[type='submit'][name]", (e) =>
    btn = $(e.currentTarget)
    click_input?.remove()
    click_input = $("<input type='hidden' />")
      .attr("name", btn.attr "name")
      .val(btn.attr "value")
      .prependTo @

  @on "submit", (e, callback) =>
    e.preventDefault()
    form = $ e.currentTarget

    if validate_fn
      return unless validate_fn? form

    form.trigger "i:before_submit"

    buttons = form.addClass("loading")
      .find("button, input[type='submit']")
      .prop("disabled", true).addClass("disabled")

    $.post form.attr("action"), form.serializeArray(), (res) =>
      buttons.prop("disabled", false).removeClass "disabled"
      form.removeClass "loading"

      if callback?
        callback? res, form
      else
        fn res, form

    null


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
