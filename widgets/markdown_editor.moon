class MarkdownEditor extends require "widgets.base"
  inner_content: =>
    textarea value: @value, placeholder: @placeholder

  js_init: =>
    @react_render "EditSubmission.Editor", {
      value: @value or ""
      placeholder: @placeholder
      name: @name
    }


