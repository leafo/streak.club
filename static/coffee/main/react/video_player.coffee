import {R, fragment, classNames} from "./_react"
import * as React from 'react'
import * as ReactDOM from 'react-dom'

import {div, button, video, source} from 'react-dom-factories'

import {with_csrf} from "main/util"

import $ from "main/jquery"

export default class VideoPlayer extends React.Component
  constructor: (props) ->
    super props
    @state = { }

  render: ->
    div {
      className: classNames "submission_video_widget", {
        loaded: !!@state.video
      }
      style: {
        aspectRatio: "#{@props.upload.width} / #{@props.upload.height}"
      }
      ref: (el) =>
        if el
          $(el).trigger "s:recalc_unroll"
    },
      if @state.video
        video {
          muted: true
          autoPlay: true
          loop: true
          width: @props.upload.width
          height: @props.upload.height
        },
          source {
            src: @state.video.url
            type: "video/mp4"
          }
      else
        button {
          className: "button"
          onClick: =>
            return if @state.loading
            @setState loading: true
            $.post(@props.video_url, with_csrf()).then (res) =>
              @setState video: res
        }, "Play Video"

