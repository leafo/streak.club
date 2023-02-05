import {R, fragment, classNames} from "./_react"
import * as React from 'react'
import * as ReactDOM from 'react-dom'

import {div, button, video, source, img} from 'react-dom-factories'

import {with_csrf} from "main/util"

import $ from "main/jquery"

export default class VideoPlayer extends React.Component
  constructor: (props) ->
    super props
    @state = { }

  load_video: =>
    return if @state.loading
    @setState loading: true
    $.post(@props.video_url, with_csrf()).then (res) =>
      @setState video: res
      @setState loading: false

      if res.url
        create_video_thumbnail res.url

  componentDidMount: ->
    if @props.autoplay
      @load_video()

  render: ->
    div {
      className: classNames "submission_video_widget", {
        loaded: !!@state.video
      }
      style: {
        aspectRatio: "#{@props.upload.width} / #{@props.upload.height}"
      }
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
        fragment {},
          if @props.thumbnail
            img {
              className: "video_thumbnail"
              src: @props.thumbnail.data_url
              width: @props.thumbnail.width
              height: @props.thumbnail.height
            }

          button {
            className: "button play_btn"
            onClick: @load_video
          }, "Play Video"

