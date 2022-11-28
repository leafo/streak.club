class SubmissionLiker extends require "widgets.base"
  new: (@props) =>

  @es_module: [[
    import SubmissionList from "main/react/submission_list"
    import {createRoot} from 'react-dom/client';
    createRoot(document.querySelector(widget_selector)).render(SubmissionList.LikeButton(widget_params))
  ]]

  js_init: =>
    super @props

