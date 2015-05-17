
class FormHelpers
  text_input_row: (opts) =>
    inside = ->
      if opts.between
        opts.between!

      if opts.type == "textarea"
        textarea {
          required: opts.required and "required"
          placeholder: opts.placeholder
          name: opts.name
          autocorrect: opts.mobile and "off" or nil
          autocapitalize: opts.mobile and "off" or nil
        }, opts.value
      else
        input {
          type: opts.type or "text"
          required: opts.required and "required"
          placeholder: opts.placeholder
          pattern: opts.pattern
          name: opts.name
          value: opts.value
          class: opts.class

          autocorrect: opts.mobile and "off" or nil
          autocapitalize: opts.mobile and "off" or nil
        }

    @input_row opts.label, opts.sub, inside, true

  input_row: (title, sub, fn, wrap_label=false) =>
    if type(sub) == "function"
      fn = sub
      sub = nil

    div class: "input_row", ->
      label_inside = ->
        div class: "label", ->
          text title
          if sub
            span class: "sub", ->
              raw " &mdash; "
              text sub
        fn!

      if wrap_label
        label label_inside
      else
        label_inside!

  -- @checkboxes "game", {
  --   {"p_windows", "Windows"}
  --   {"p_linux", "Linux"}
  -- }, @game
  checkboxes: (prefix, options, object) =>
    empty = {}
    ul class: "check_list", ->
      for {opt_value, opt_label, opt_sub, opts} in *options
        li opts or empty, ->
          label ->
            checked = object[opt_value] and "checked" or nil
            name = "#{prefix}[#{opt_value}]"

            input type: "checkbox", :name, :checked
            text opt_label
            if opt_sub
              span class: "sub", ->
                raw " &mdash; "
                text opt_sub

  radio_buttons: (name, options, current_value) =>
    ul class: "radio_list", ->
      for {opt_value, opt_label, opt_sub} in *options
        li ->
          label ->
            checked = current_value == opt_value and "checked" or nil
            input type: "radio", value: opt_value, :name, :checked
            text opt_label
            if opt_sub
              span class: "sub", ->
                raw " &mdash; "
                text opt_sub

