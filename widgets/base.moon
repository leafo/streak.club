
import underscore, time_ago_in_words from require "lapis.util"

import is_type from require "tableshape"

import random from math
import concat from table

import to_json from require "lapis.util"

date = require "date"

if ngx and ngx.worker
  math.randomseed ngx.time! + ngx.worker.pid!
else
  math.randomseed os.time!

import types from require "tableshape"

class Base extends require "lapis.eswidget"
  @include "widgets.helpers"
  @include "widgets.asset_helpers"
  @include "widgets.icons"

  -- the package name where this widget's assets will go
  @asset_packages: {"main"}

  @js_init_method_name: =>
   "init_#{@__name}"

  -- this splits apart the js_init into two parts
  -- js_init must be a class method
  @compile_js_init: =>
    -- TODO: how should this work with inheriting?
    return nil, "no @@js_init" unless rawget @, "js_init"

    -- split import and non-import statemetns
    import_lines = {}
    code_lines = {}

    import trim from require "lapis.util"

    for line in @js_init\gmatch "([^\r\n]+)"
      continue if line\match "^%s*$"

      if line\match "^%s*import"
        table.insert import_lines, trim line
      else
        table.insert code_lines, line

    table.concat {
      table.concat import_lines,  "\n"
      "window.#{@js_init_method_name!} = function(widget_selector, widget_params) {"
      table.concat code_lines, "\n"
      "}"
    }, "\n"

  @get_asset_file: do
    valid_formats = types.one_of {"scss", "coffee"}

    (format) =>
      prefix = unpack @asset_packages
      assert valid_formats format
      switch format
        when "scss"
          "static/scss/#{prefix}/#{@widget_name!}.scss"
        when "coffee"
          "static/coffee/#{prefix}/#{@widget_name!}.scss"

  @widget_name: => underscore @__name or "some_widget"

  -- returns array of widget names for class list
  -- will abort as base, will skip mixins classes
  @class_hierarchy: =>
    current = @
    out = {}
    while current
      break if current == Base

      unless rawget(current, "_mixins_class")
        if name = current\widget_name!
          table.insert out, name

      current = current.__parent

    out

  -- classes chained from inheritance hierarchy
  @css_classes: =>
    return if @ == Base

    unless rawget @, "_css_classes"
      @_css_classes = table.concat @class_hierarchy!, " "

    @_css_classes

  new: (opts, ...) =>
    if @@prop_types
      @props, state = if is_type @@prop_types
        assert @@prop_types\transform opts or {}
      else
        assert type(opts) == "table" and opts

      -- if the prop types generates any state we can just store it directly
      -- into the instance. Is this a bad idea? What if things generated state
      -- as side effect, they will need to be scoped
      if state
        for k, v in pairs state
          @[k] = v

    else
      super opts, ...

  -- render: (...) =>
  --   if @@needs
  --     require("moon").p {
  --       name: @@__name
  --       needs: @@needs
  --     }

  --   super ...

  inner_content: =>

  -- default js_init will use the init method name and static init code use
  -- super to insert run time params by overriding. The rendering caller will
  -- never pass arguments
  js_init: (widget_params=nil) =>
    return nil unless rawget @@, "js_init"
    method_name = @@js_init_method_name!
    return unless method_name

    "#{method_name}(#{@widget_selector!}, #{to_json widget_params});"

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
