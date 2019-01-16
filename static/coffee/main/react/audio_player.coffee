P = R.package "SubmissionList"


# passed to props to the audio track list
PLAYER_STATE = {
  audio_files: []
}

P "AudioTrackList", {
  getDefaultProps: ->
    { audio_files: [] }

  getInitialState: ->
    {
      show_list: false
      closed: false
    }

  render: ->
    if @state.closed
      return null

    active_file = @props.active_file

    div className: "audio_sticky_player",
      button {
        type: "button"
        disabled: !@props.active_file || @props.active_file_loading
        className: classNames {
          "toggle_play_button"
          disabled: !@props.active_file || @props.active_file_loading
          loading: @props.active_file_loading
        }
      }, if @props.active_file_playing
          R.Icons.PauseIcon width: 30, height: 30
        else
          R.Icons.PlayIcon width: 30, height: 30

      button {
        type: "button"
      }, R.Icons.NextTrackIcon()

      div className: "track_area",
        if @state.show_list
          @render_track_list()

        div className: "current_playing",
          if active_file
            React.createElement React.Fragment, {},
              strong {
                className: "track_title",
                onClick: (e) =>
                  e.preventDefault()
                  el = ReactDOM.findDOMNode(active_file)
                  el.scrollIntoView?()
              },
                active_file.props.upload.filename
              " — "
              span className: "user", active_file.props.submission.user_name
          else
            div className: "empty_track", "No track"

        R.Forms.Slider {
          min: 0
          max: 500
          value: (@props.active_file_progress || 0) * 500 / 100
          disabled: !@props.active_file
          onChange: (val) =>
            console.log "val": val
        }

      button {
        type: "button"
        title: if @state.show_list then "Hide" else "Tracks"
        className: classNames {
          "toggle_tracklist_button"
          active: @state.show_list
        }
        onClick: =>
          @setState (s) -> show_list: !s.show_list
      }, R.Icons.PlaylistIcon width: 16, height: 16

      button {
        type: "button"
        onClick: =>
          @setState closed: true
      }, R.Icons.CloseIcon width: 14, height: 14

  render_track_list: ->
    div className: "track_list_popup",
      ul className: "file_list",
        @props.audio_files.map (file, idx) =>
          upload = file.props.upload
          li {
            key: upload.id,
            className: classNames {
              active: @props.active_file == file
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

track_list_drop = null

render_track_list = (props) ->
  unless track_list_drop
    track_list_drop = $('<div class="audio_track_list_drop"></div>').appendTo document.body

  PLAYER_STATE = Object.assign {}, PLAYER_STATE, props
  track_list = P.AudioTrackList PLAYER_STATE

  ReactDOM.render track_list, track_list_drop[0]

P "AudioFile", {
  getInitialState: ->
    { playing: false, loading: false }

  componentDidUpdate: (prev_props, prev_state) ->
    if PLAYER_STATE.active_file == @
      render_track_list {
        active_file_playing: @state.playing
        active_file_loading: @state.loading
        active_file_progress: @state.progress
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
    return if @state.loading
    @state.audio?.pause()

  play_audio: (e) ->
    e?.preventDefault()
    return if @state.loading

    @pause_others()

    render_track_list {
      active_file: @
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

      $.post @props.audio_url, S.with_csrf(), (res) =>
        # switched songs while loading
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

      form {
        className: "download_form"
        method: "post"
        action: @props.download_url
      },
        input type: "hidden", name: "csrf_token", value: S.get_csrf()
        button className: "upload_download button", "Download"

      div className: "truncate_content",
        if @state.error
          span {
            className: "playback_error"
            title: @state.error
          }, "Failed to load audio"
        else
          React.createElement React.Fragment, {},
            span className: "upload_name", @props.upload.filename
            span className: "upload_size", S.format_bytes @props.upload.size

        if @state.played
          div className: "audio_progress_outer",
            div className: "audio_progress_inner", style: { width: "#{@state.progress || 0}%" }

}
