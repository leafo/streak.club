import {R, fragment, classNames} from "./_react"

import * as React from 'react'

P = R.package "ReferenceSession"

import {div, button, span, svg, circle} from 'react-dom-factories'

import $ from "main/jquery"
import {with_csrf} from "main/util"

import {UploadManager} from "main/upload"

ProgressBar = (props) ->
  radius = props.radius ? 50
  strokeWidth = props.strokeWidth ? 10
  normalizedRadius = radius - strokeWidth * 2
  circumference = normalizedRadius * 2 * Math.PI
  strokeDashoffset = circumference - (props.progress / 100) * circumference

  svg {
    height: 2 * radius
    width: 2 * radius
  },
    circle {
      stroke: "#e6e6e6"
      fill: "transparent"
      strokeWidth: strokeWidth
      r: normalizedRadius
      cx: radius
      cy: radius
    }

    circle {
      stroke: "#00aaff"
      fill: "transparent"
      strokeWidth: strokeWidth
      strokeDasharray: "#{circumference} #{circumference}"
      style: { strokeDashoffset }
      r: normalizedRadius
      cx: radius
      cy: radius
      transform: "rotate(-90 #{radius} #{radius})"
    }


ProgressBar = React.memo ProgressBar


ImageUpload = (props) ->

      React.createElement ProgressBar, progress: 10


ImageUpload = React.memo ImageUpload



export ReferenceSession = P "ReferenceSession", {
  getInitialState: ->
    {
      upload_manager: new UploadManager @props.uploader_opts
      uploads: []
    }

  fetch_state: ->
    $.post("", with_csrf())
      .always =>
        setTimeout @fetch_state, 2000

      .then (res) =>
        if res.state
          @setState res.state

  componentDidMount: ->
    @fetch_state()

  push_upload: (upload) ->
    @setState (state) -> {
      uploads: state.uploads.concat(upload)
    }

    # TODO: remove the use of forceUpdate
    upload.on_update = => @forceUpdate()

  pick_upload: (e) ->
    e.preventDefault()

    @state.upload_manager.pick_file(@push_upload).then (upload) =>
      @setState {
        active_upload: upload
      }

  render: ->
    div {
      className: "empty_display"
    },

      button {
        className: "button"
        onClick: @pick_upload
      }, "Upload image"

      span {}, "Paste or drop image to share it"
}

