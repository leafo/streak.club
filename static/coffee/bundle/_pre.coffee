
_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g
  evaluate: /<%([\s\S]+?)%>/g
}

window.S = {
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
            btn.toggleClass "following"
    }
}

$.fn.dispatch = (event_type, table) ->
  @on event_type, (e) =>
    for key, fn of table
      elm = $(e.target).closest ".#{key}"
      continue unless elm.length
      if elm.is ".disabled"
        e.preventDefault()
        return

      res = fn elm, e
      unless res == "continue"
        e.preventDefault()
        return
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


$.fn.set_form_errors = (errors, scroll_to=true) ->
  @find(".form_errors").remove()
  if errors?.length
    errors_el = $ """
      <div class="form_errors">
        <div>Errors:</div>
        <ul></ul>
      </div>
    """

    errors_list = errors_el.find "ul"
    for e in errors
      errors_list.append $("<li></li>").text e

    @prepend errors_el

    if scroll_to
      @[0].scrollIntoView?()

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
