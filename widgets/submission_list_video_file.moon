class SubmissionListVideoFile extends require "widgets.base"
  new: (@props) =>

  @es_module: [[
    import VideoPlayer from "main/react/video_player"
    import {createRoot} from 'react-dom/client';
    import {createElement} from 'react';

    createRoot(document.querySelector(widget_selector)).render(createElement(VideoPlayer, widget_params))
  ]]

  inner_content: =>
    div {
      class: "submission_video_widget",
      style: "aspect-ratio: #{@props.upload.width} / #{@props.upload.height}; max-height: #{@props.upload.height}px;"
    }, ->
      div class: "control_buttons", ->
        button disabled: true, class: "button", "Play Video"
        span class: "upload_size",
          "(#{@props.upload.size_formatted})"

  js_init: =>
    super @props

