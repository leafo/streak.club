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

  on_click_video: (e) =>
    if el = @video_el.current
      if el.paused
        el.play()
      else
        el.pause()

  on_time_update: (e) =>
    @setState {
      current_time: e.target.currentTime
      duration: e.target.duration
    }

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
        fragment {},
          video {
            ref: @video_el ||= React.createRef()
            muted: true
            autoPlay: true
            loop: true
            width: @props.upload.width
            height: @props.upload.height
            onTimeUpdate: @on_time_update
            onClick: @on_click_video
          },
            source {
              src: @state.video.url
              type: "video/mp4"
            }

          div className: "video_progress_bar",
            div {
              className: "video_progress_bar_inner",
              style: {
                width: "#{@state.current_time / @state.duration * 100}%"
              }
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

