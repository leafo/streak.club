class MarkdownEditor extends require "widgets.base"
  @es_module: [[
    import EditSubmission from "main/react/edit_submission"
    import {createRoot} from 'react-dom/client'

    let container = document.querySelector(widget_selector)

    widget_params.ref = function(component) {
      $(container).data("react_component", component)
    }

    createRoot(container).render(EditSubmission.Editor(widget_params))
  ]]

  js_init: =>
    super {
      value: @value or ""
      placeholder: @placeholder
      name: @name
      required: @required
    }

  inner_content: =>
    textarea readonly: true, placeholder: @placeholder, ->
      text @value


