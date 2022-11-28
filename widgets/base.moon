
import time_ago_in_words from require "lapis.util"
import types, is_type from require "tableshape"

import classnames from require "lapis.html"

date = require "date"

-- is this even needed anymore?
if ngx and ngx.worker
  math.randomseed ngx.time! + ngx.worker.pid!
else
  math.randomseed os.time!

class Base extends require "lapis.eswidget"
  @include "widgets.helpers"
  @include "widgets.asset_helpers"
  @include "widgets.icons"

  @widget_class_list: =>
    -- don't include class for base widget
    if @ == Base
      return

    super!

  -- TODO: unfortuantely streak.club never used the _widget suffix, this will
  -- require a manual refactor of all CSS. So we default to using the plain
  -- widget name as the class name instead
  @widget_class_name: =>
    @widget_name!

  @asset_packages: {"main"}

  -- TODO: we aren't using this right now, but could be helpful at some point
  -- @get_asset_file: do
  --   valid_formats = types.one_of {"scss", "coffee"}

  --   (format) =>
  --     prefix = unpack @asset_packages
  --     assert valid_formats format
  --     switch format
  --       when "scss"
  --         "static/scss/#{prefix}/#{@widget_name!}.scss"
  --       when "coffee"
  --         "static/coffee/#{prefix}/#{@widget_name!}.coffee"

  -- TODO: this is currently overriding the EsWidget's default functionality
  -- lets just remove support for state injection and then use the regular behavior
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


  -- this is to support the old widget_classes interface
  widget_enclosing_attributes: =>
    attributes = super!
    attributes.class = @widget_classes!
    attributes

  widget_classes: =>
    classnames { @@widget_class_list! }

  -- TODO: see if this is something we want
  -- render: (...) =>
  --   if @@needs
  --     require("moon").p {
  --       name: @@__name
  --       needs: @@needs
  --     }

  --   super ...

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
