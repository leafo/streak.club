
_.templateSettings = {
  interpolate : /\{\{(.+?)\}\}/g
  escape : /\{\{&(.+?)\}\}/g
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

  format_dates: (outer, method="calendar", args=[]) ->
    for el in outer.find(".date_format")
      do (el=$ el) ->
        real_method = el.data("format_method") || method
        method_args = el.data("format_args") || args

        unless _.isArray method_args
          method_args = [method_args]

        full_date = el.html()
        el.html(moment.utc(full_date).local()[real_method](method_args...))
          .attr "title", full_date
}

$.fn.dispatch = (event_type, selector, table) ->
  if $.isPlainObject selector
    table = selector
    selector = undefined

  handler = (e) =>
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

  if selector
    @on event_type, selector, handler
  else
    @on event_type, handler

$.fn.remote_submit = (selector, fn, validate_fn) ->
  click_input = null

  if $.isFunction selector
    validate_fn = fn
    fn = selector
    selector = undefined


  prefix = selector || ""
  @on "click", "#{prefix} button[name], #{prefix} input[type='submit'][name]", (e) =>
    btn = $(e.currentTarget)
    form = btn.closest("form")

    click_input?.remove()
    click_input = $("<input type='hidden' />")
      .attr("name", btn.attr "name")
      .val(btn.attr "value")
      .prependTo form

  submit_callback = (e, callback) =>
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

  if selector
    @on "submit", selector, submit_callback
  else
    @on "submit", submit_callback

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

  @

# TODO: use on collections page
$.fn.swap_with = (other) ->
  other = $ other
  return unless @length && other.length

  offset = @offset()
  other_offset = other.offset()

  tag_name = @prop "tagName"
  other_tag_name = other.prop "tagName"

  placeholder = $("<#{tag_name}></#{tag_name}>").insertAfter @
  other_placeholder = $("<#{other_tag_name}></#{other_tag_name}>").insertAfter other

  placeholder.after other
  other_placeholder.after @

  new_offset = @offset()
  other_new_offset = other.offset()

  other_placeholder.replaceWith @detach().css({
    position: "relative"
    top: "#{offset.top - new_offset.top}px"
    left: "#{offset.left - new_offset.left}px"
  })

  placeholder.replaceWith other.detach().css {
    position: "relative"
    top: "#{other_offset.top - other_new_offset.top}px"
    left: "#{other_offset.left - other_new_offset.left}px"
  }

  _.defer =>
    @css { top: "", left: "" }
    other.css { top: "", left: "" }

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
