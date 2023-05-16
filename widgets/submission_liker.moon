class SubmissionLiker extends require "widgets.base"
  new: (@props) =>

  @es_module: [[
    import {LikeButton} from "main/react/submission_list"
    import {createRoot} from 'react-dom/client';
    createRoot(document.querySelector(widget_selector)).render(LikeButton(widget_params))
  ]]

  js_init: =>
    super @props

