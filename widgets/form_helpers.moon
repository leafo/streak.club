
class FormHelpers
  text_input_row: (opts) =>
    div class: "input_row", ->
      label ->
        div class: "label", ->
          text opts.label
          if opts.sub
            span class: "sub", ->
              raw " &mdash; "
              text opts.sub

        input {
          type: opts.type or "text"
          required: opts.required and "required"
          placeholder: opts.placeholder
          pattern: opts.pattern
          name: opts.name
          value: opts.value
        }


