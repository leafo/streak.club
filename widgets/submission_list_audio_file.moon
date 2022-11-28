class SubmissionListAudioFile extends require "widgets.base"
  new: (@props) =>

  @es_module: [[
    import AudioPlayer from "main/react/audio_player"
    import {createRoot} from 'react-dom/client';
    createRoot(document.querySelector(widget_selector)).render(AudioPlayer.AudioFile(widget_params))
  ]]

  inner_content: =>
    div class: "submission_audio", ->
      button class: "play_audio_btn"

      div class: "download_form", ->
        button class: "upload_download button", style: "color: rgba(0,0,0,0)", "Download"

  js_init: =>
    super @props

