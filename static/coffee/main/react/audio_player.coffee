import {R, fragment, classNames} from "./_react"
import * as React from 'react'
import * as ReactDOM from 'react-dom'
import {createRoot} from "react-dom/client"

import $ from "main/jquery"

import {div, button, ul, li, span, a, form, input, img} from 'react-dom-factories'

import {HeartIcon, PauseIcon, PlayIcon, NextTrackIcon, PlaylistIcon, CloseIcon} from "./icons"

import {LikeButton, LikeButtonProvider} from "./submission_list"

import Slider from "./slider"

import {with_csrf, get_csrf, format_bytes} from "main/util"

P = R.package "AudioPlayer"

format_seconds = (n) ->
  minutes = Math.floor n / 60
  secs = Math.floor(n) % 60

  "#{minutes}:#{("00" + secs).substr -2}"

# passed to props to the audio track list
PLAYER_STATE = {
  audio_files: []
  closed: true
}

export TrackListPopup = P "TrackListPopup", {
  pure: true

  componentDidMount: ->
    @active_row_ref.current?.scrollIntoView?()
    $(document.body).on "click", @body_click

  componentWillUnmount: ->
    $(document.body).off "click", @body_click

  body_click: (e) ->
    el = ReactDOM.findDOMNode @props.parent
    found = $(e.target).closest el
    unless found.length
      @props.parent.setState show_list: false

  render: ->
    div className: "track_list_popup",
      ul className: "file_list",
        @props.audio_files.map (file, idx) =>
          upload = file.props.upload
          is_active = @props.active_file == file

          li {
            key: upload.id,
            ref: if is_active
              @active_row_ref ||= React.createRef()
            className: classNames {
              active: is_active
              # TODO: this needs to be communicated with state
              loading: file.state.loading
            }
          },
            button {
              type: "button"
              className: "play_file_btn"
              onClick: (e) =>
                e.preventDefault()
                file.play_audio()
            },
              span className: "filename", upload.filename
              " — "
              span className: "user", file.props.submission.user_name

}

export StickyAudioPlayer = P "StickyAudioPlayer", {
  getDefaultProps: ->
    { audio_files: [] }

  getInitialState: ->
    {
      show_list: false
      closed: false
    }

  componentDidMount: ->
    el = ReactDOM.findDOMNode @
    $(el).has_tooltips()

  render_like_button: (props) ->
    if props
      LikeButton Object.assign {
        quick_comment: false
        show_count: false
        icon: HeartIcon width: 18, height: 18
      }, props
    else
      button {
        type: "button"
        className: "toggle_like_button"
        disabled: true
      }, HeartIcon width: 18, height: 18

  on_change_slider: (val) ->
    @props.active_file?.seek_audio val

  render: ->
    if @props.closed
      return null

    active_file = @props.active_file
    submission_id = active_file?.props?.submission?.id

    div className: "audio_sticky_player",
      button {
        type: "button"
        disabled: !@props.active_file || @props.active_file_loading
        className: classNames {
          "toggle_play_button"
          disabled: !@props.active_file || @props.active_file_loading
          loading: @props.active_file_loading
        }
        onClick: (e) =>
          e.preventDefault()
          if @props.active_file_playing
            active_file.pause_audio()
          else
            active_file.play_audio()

      }, if @props.active_file_playing
          PauseIcon width: 30, height: 30
        else
          PlayIcon width: 30, height: 30

      button {
        type: "button"
        onClick: (e) =>
          e.preventDefault()
          idx = @props.audio_files.indexOf(@props.active_file)
          next = @props.audio_files[idx + 1] || @props.audio_files[0]
          next?.play_audio()
      }, NextTrackIcon()

      LikeButtonProvider {
        key: "s#{submission_id}"
        submission_id: submission_id
        render_with_props: @render_like_button
      }

      div className: "track_area",
        if @state.show_list
          @render_track_list()

        div className: "current_playing",
          if active_file
            fragment {},
              if @props.active_file_current_time
                span className: "current_time",
                  format_seconds @props.active_file_current_time

              span {},
                a {
                  role: "button"
                  className: "track_title",
                  href: "#"
                  onClick: (e) =>
                    e.preventDefault()
                    if submission_id = active_file.props.submission?.id
                      $("[data-submission_id=#{submission_id}]").find(".submission_content").focus()
                    else
                      el = ReactDOM.findDOMNode(active_file)
                      el.scrollIntoView?()
                }, active_file.props.upload.filename
                " — "
                a {
                  className: "user"
                  href: active_file.props.submission.user_url
                  target: "blank"
                }, active_file.props.submission.user_name

              if @props.active_file_duration
                span className: "duration",
                  format_seconds @props.active_file_duration
          else
            div className: "empty_track", "No track"

        Slider {
          min: 0
          max: @props.active_file_duration || 1
          value: @props.active_file_current_time || 0
          disabled: !@props.active_file
          onChange: @on_change_slider
        }

      button {
        type: "button"
        title: if @state.show_list then "Hide" else "Track list"
        className: classNames {
          "toggle_tracklist_button"
          active: @state.show_list
        }
        onClick: =>
          @setState (s) -> show_list: !s.show_list
      }, PlaylistIcon width: 16, height: 16

      button {
        type: "button"
        title: "Stop & close"
        onClick: =>
          render_track_list closed: true
          @props.active_file?.pause_audio()
      }, CloseIcon width: 14, height: 14

  render_track_list: ->
    TrackListPopup {
      parent: @
      audio_files: @props.audio_files
      active_file: @props.active_file
    }
}

track_list_root = null

render_track_list = (props) ->
  unless track_list_root
    track_list_root = createRoot $('<div class="audio_track_list_drop"></div>').appendTo(document.body)[0]

  PLAYER_STATE = Object.assign {}, PLAYER_STATE, props
  track_list_root.render StickyAudioPlayer PLAYER_STATE

export AudioFile = P "AudioFile", {
  getInitialState: ->
    { playing: false, loading: false }

  componentDidUpdate: (prev_props, prev_state) ->
    if PLAYER_STATE.active_file == @
      render_track_list {
        active_file_playing: @state.playing
        active_file_loading: @state.loading

        active_file_duration: @state.duration
        active_file_current_time: @state.current_time
      }

  componentDidMount: ->
    render_track_list {
      audio_files: PLAYER_STATE.audio_files.concat([@])
    }

  componentWillUnmount: ->
    if @state.audio && !@state.audio.paused
      @state.audio.pause()

    render_track_list {
      audio_files: (o for o in PLAYER_STATE.audio_files when o != this)
      active_file: if PLAYER_STATE.active_file == @
        null
      else
        PLAYER_STATE.active_file
    }

  pause_others: ->
    for file in PLAYER_STATE.audio_files
      continue if file == @
      file.pause_audio()

  pause_audio: (e) ->
    e?.preventDefault()
    if @state.audio
      @state.audio?.pause()

  seek_audio: (time) ->
    @state.audio?.currentTime = time
    @setState current_time: time

  play_audio: (e) ->
    e?.preventDefault()
    return if @state.loading

    @pause_others()

    render_track_list {
      active_file: @
      closed: false
    }

    if @state.audio
      @state.audio.play()?.catch? (e) =>
        # audio url probably expired, just clear it so they can load it again
        # on next play. TODO: better fix
        @setState audio: false

      @setState playing: true
    else
      @setState {
        loading: true
        played: false
        error: null
      }

      $.post @props.audio_url, with_csrf(), (res) =>
        if PLAYER_STATE.active_file != @
          @setState loading: false
          return

        if res.url
          @play_url res.url
        else
          @setState loading: false

  play_url: (url) ->
    audio = document.createElement "audio"

    unless audio.canPlayType "audio/mpeg"
      alert "Yikes, doesn't look like your browser supports playing MP3s"
      return false

    audio.setAttribute "src", url
    audio.play()?.catch? (e) =>
      message = e.message
      @setState error: message, loading: false, audio: null

    audio.addEventListener "canplay", =>
      @setState loading: false

    audio.addEventListener "pause", =>
      @setState playing: false

    audio.addEventListener "timeupdate", =>
      @setState {
        loading: false
        played: true
        playing: true
        progress: audio.currentTime / audio.duration * 100

        duration: audio.duration
        current_time: audio.currentTime
      }

    audio.addEventListener "ended", =>
      @setState playing: false

    @setState { audio }

    true

  render: ->
    div className: classNames("submission_audio", loading: @state.loading),
      button {
        className: classNames "play_audio_btn", disabled: @state.loading
        type: "button"
        onClick: if @state.playing then @pause_audio else @play_audio
        disabled: @state.loading
      },
        if @state.playing
          img className: "pause_icon", src: "/static/images/audio_pause.svg"
        else
          img className: "play_icon", src: "/static/images/audio_play.svg"

      if @state.error
        span {
          className: "playback_error"
          title: @state.error
        }, "Failed to load audio"
      else
        div className: "playback_area",
          fragment {},
            span className: "upload_name", @props.upload.filename
            span className: "upload_size", format_bytes @props.upload.size

          if @state.played
            div className: "audio_progress_outer",
              div className: "audio_progress_inner", style: { width: "#{@state.progress || 0}%" }

      form {
        className: "download_form"
        method: "post"
        action: @props.download_url
      },
        input type: "hidden", name: "csrf_token", value: get_csrf()
        button className: "upload_download button", "Download"



}
