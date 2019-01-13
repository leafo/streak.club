P = R.package "SubmissionList"

all_files = []

P "AudioFile", {
  getInitialState: ->
    { playing: false, loading: false }

  componentDidMount: ->
    all_files = all_files.concat([@])

  componentWillUnmount: ->
    if @state.audio && !@state.audio.paused
      @state.audio.pause()

    all_files = (o for o in all_files when o != this)

  pause_others: ->
    for file in all_files
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
