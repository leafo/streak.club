class MarkdownEditor extends require "widgets.base"
  inner_content: =>
    textarea placeholder: @placeholder, ->
      text @value

  js_init: =>
    @react_render "EditSubmission.Editor", {
      value: @value or ""
      placeholder: @placeholder
      name: @name
      required: @required
    }


