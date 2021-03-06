
dayjs.extend window.dayjs_plugin_duration
dayjs.extend window.dayjs_plugin_calendar
dayjs.extend window.dayjs_plugin_advancedFormat

window.S = {
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
      if _gaq
        _gaq.push params
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


class S.InfiniteScroll
  loading_element: ".list_loader"

  constructor: (el, opts={}) ->
    @el = $ el
    $.extend @, opts
    @setup_loading()

  get_next_page: ->
    alert "override me"

  setup_loading: ->
    @loading_row = @el.find @loading_element
    return unless @loading_row.length

    win = $(window)
    check_scroll_pos = =>
      return if @el.is ".loading"
      if win.scrollTop() + win.height() >= @loading_row.offset().top
        @get_next_page()

    check_scroll_pos = _.throttle check_scroll_pos, 100

    win.on "scroll.browse_loader", check_scroll_pos
    _.defer => check_scroll_pos()

  remove_loader: ->
    $(window).off "scroll.browse_loader"
    @loading_row.remove()

