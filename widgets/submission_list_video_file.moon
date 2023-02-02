class SubmissionListVideoFile extends require "widgets.base"
  new: (@props) =>

  @es_module: [[
    import VideoPlayer from "main/react/video_player"
    import {createRoot} from 'react-dom/client';
    import {createElement} from 'react';

    createRoot(document.querySelector(widget_selector)).render(createElement(VideoPlayer, widget_params))
  ]]

  inner_content: =>
    div class: "submission_video_widget", "Hello Zone"

  js_init: =>
    super @props

