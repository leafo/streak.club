import {R, fragment, classNames} from "./_react"
import * as React from 'react'
import * as ReactDOM from 'react-dom'

import {div, button, video, source, img, form, input, span} from 'react-dom-factories'

import {with_csrf, get_csrf} from "main/util"

import $ from "main/jquery"

import {DownloadIcon} from "main/react/icons"

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

  on_play: (e) =>
    @setState playing: true, @update_progress

  on_pause: (e) =>
    @setState playing: false, @update_progress

  componentWillUnmount: =>
    if @progress_tick
      cancelAnimationFrame @progress_tick

    if @observer
      @observer.disconnect()

  update_progress: =>
    el = @video_el.current
    return unless el

    @setState {
      current_time: el.currentTime
      duration: el.duration
    }

    if @state.playing and not @progress_tick
      @progress_tick = requestAnimationFrame =>
        delete @progress_tick
        @update_progress()

  on_click_video: (e) =>
    if el = @video_el.current
      if el.paused
        el.play()
      else
        el.pause()

  componentDidMount: ->
    if @props.autoplay
      @load_video()

    if "IntersectionObserver" of window
      @observer = new IntersectionObserver (entries) =>
        for entry in entries
          if not entry.isIntersecting and @state.playing
            @video_el.current.pause()

      @observer.observe @container_el.current

  render: ->
    div {
      ref: @container_el ||= React.createRef()

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
            tabIndex: 0
            ref: @video_el ||= React.createRef()
            autoPlay: true
            loop: true
            width: @props.upload.width
            height: @props.upload.height
            onClick: @on_click_video
            onPause: @on_pause
            onPlay: @on_play
          },
            source {
              src: @state.video.url
              type: "video/mp4"
            }

          div className: classNames("video_progress_bar", playing: @state.playing),
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

          div className: "control_buttons",
            button {
              className: "button play_btn"
              onClick: @load_video
            }, "Play Video"

            form {
              className: "download_form"
              method: "post"
              action: @props.download_url
            },
              input type: "hidden", name: "csrf_token", value: get_csrf()
              button {
                title: "Download"
                className: "download_btn"
              }, DownloadIcon()

            span className: "upload_size", title: @props.upload.filename,
              "(#{@props.upload.size_formatted})"


