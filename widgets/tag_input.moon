class TagInput extends require "widgets.base"
  @es_module: [[
    import EditSubmission from "main/react/edit_submission"
    import {createRoot} from 'react-dom/client';
    createRoot(document.querySelector(widget_selector)).render(EditSubmission.TagInput(widget_params))
  ]]

  js_init: =>
    super {
      tags: @tags
      placeholder: @placeholder
      name: @name
      required: @required
      suggested_tags: @suggested_tags
    }

  inner_content: =>
    input type: "text", name: @name, value: table.concat @tags or {}, ","
