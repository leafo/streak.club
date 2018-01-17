class TagInput extends require "widgets.base"
  inner_content: =>
    input type: "text", name: @name, value: table.concat @tags or {}, ","

  js_init: =>
    @react_render "EditSubmission.TagInput", {
      tags: @tags
      placeholder: @placeholder
      name: @name
      required: @required
      suggested_tags: @suggested_tags
    }

