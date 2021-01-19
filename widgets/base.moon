
import Widget from require "lapis.html"
import underscore, time_ago_in_words from require "lapis.util"

import random from math
import concat from table

import to_json from require "lapis.util"

date = require "date"

if ngx and ngx.worker
  math.randomseed ngx.time! + ngx.worker.pid!
else
  math.randomseed os.time!

truncate = do
  import C, Cmt from require "lpeg"
  import printable_character, whitespace from require "lapis.util.utf8"

  nonwhitespace = 1 - whitespace
  trim_right = C (whitespace^0 * nonwhitespace^1)^0

  remaining = 0
  truncator = C Cmt(printable_character, (pos) ->
    remaining -= 1
    remaining >= 0
  )^0

  (str, len) ->
    remaining = assert len, "missing length"

    if #str < remaining
      return str

    trim_right\match truncator\match(str) or ""

class Base extends Widget
  @include "widgets.asset_helpers"
  @include "widgets.icons"

  @widget_name: => underscore @__name or "some_widget"

  -- classes chained from inheritance hierarchy
  @css_classes: =>
    return if @ == Base

    unless rawget @, "_css_classes"
      classes = @widget_name!
      if @__parent and @__parent.css_classes
        if parent_classes = @__parent\css_classes!
          classes ..= " #{parent_classes}"

      @_css_classes = classes

    @_css_classes


  inner_content: =>

  content: (fn=@inner_content) =>
    classes = @widget_classes!

    local inner
    @_opts = { class: classes, -> raw inner }

    append_js = if @js_init
      @widget_id!
      if js = @js_init!
        if @layout_opts
          @content_for "js_init", ->
            raw js
            unless js\match ";%s$"
              raw ";"
          nil
        else
          js


    inner = capture -> fn @
    element @elm_type or "div", @_opts

    if append_js
      script type: "text/javascript", ->
        raw append_js

  widget_classes: =>
    @css_class or @@css_classes!

  widget_id: =>
    unless @_widget_id
      @_widget_id = "#{@@widget_name!}_#{random 0, 10000000}"
      @_opts.id or= @_widget_id if @_opts
    @_widget_id

  widget_selector: =>
    "'##{@widget_id!}'"

  csrf_input: =>
    input type: "hidden", name: "csrf_token", value: @csrf_token

  raw_ssi: (fname) =>
    res = ngx.location.capture "/static/#{fname}"
    error "Failed to include SSI '#{fname}' (#{res.status})" unless res.status == 200
    raw res.body

  render_errors: =>
    if @errors
      div class: "form_errors", ->
        div "Errors:"
        ul ->
          for e in *@errors
            li e

  relative_timestamp: (d) =>
    now = date true

    suffix = if date(true) < date(d)
      "from now"
    else
      "ago"

    time_ago_in_words tostring(d), nil, suffix

  plural: (num, single, plural) =>
    if num == 1 or num == "1"
      "#{num} #{single}"
    else
      "#{num} #{plural}"

  js_template: (name, fn) =>
    script type: "text/template", id: "#{name}_tpl", ->
      old_t = @_buffer.in_template
      @_buffer.in_template = true
      raw capture fn
      @_buffer.in_template = old_t

  date_format: (d, extra_opts) =>
    if type(d) == "string"
      date = require "date"
      d = date(d)

    opts = {
      class: "date_format"
      title: tostring(d)
    }

    if extra_opts
      for k,v in pairs extra_opts
        if k == "class"
          opts[k] = opts[k] .. " " .. v
        else
          opts[k] = v

    span opts, d\fmt "${iso}Z"

  filesize_format: do
    limits = {
      {"gb", 1024^3}
      {"mb", 1024^2}
      {"kb", 1024}
    }

    (bytes) =>
      bytes = math.floor bytes
      suffix = " bytes"
      for {label, min} in *limits
        if bytes >= min
          bytes = math.floor bytes / min
          suffix = label
          break

      @number_format(bytes) .. suffix

  number_format: (num) =>
    tostring(num)\reverse!\gsub("(...)", "%1,")\match("^(.-),?$")\reverse!

  truncate: (str, len=30, tail="...") =>
    out = truncate str, len
    if out != str and tail
      out .. tail
    else
      out

  react_render: (component, props={}, selector) =>
    target = "$(#{@widget_selector!})"
    if selector
      target ..= ".find(#{to_json selector})"

    "#{target}.data('react_component', ReactDOM.render(R.#{component}(#{to_json props}),#{target}[0]));"
