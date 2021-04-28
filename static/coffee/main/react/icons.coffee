import {createElement} from 'react'

export PlaylistIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon playlist_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "path", {
      d: "M16 17a3 3 0 0 1-3 3h-2a3 3 0 0 1 0-6h2a3 3 0 0 1 1 .17V1l6-1v4l-4 .67V17zM0 3h12v2H0V3zm0 4h12v2H0V7zm0 4h12v2H0v-2zm0 4h6v2H0v-2z"
    }

export CloseIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon close_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "path", {
      d: "M10 8.586L2.929 1.515 1.515 2.929 8.586 10l-7.071 7.071 1.414 1.414L10 11.414l7.071 7.071 1.414-1.414L11.414 10l7.071-7.071-1.414-1.414L10 8.586z"
    }

export PlayIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon play_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "path", {
      d: "M4 4l12 6-12 6z"
    }

export PauseIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon pause_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "path", {
      d: "M5 4h3v12H5V4zm7 0h3v12h-3V4z"
    }

export NextTrackIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon next_track_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "path", {
      d: "M13 5h3v10h-3V5zM4 5l9 5-9 5V5z"
    }

export PrevTrackIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon prev_track_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "path", {
      d: "M4 5h3v10H4V5zm12 0v10l-9-5 9-5z"
    }


export HeartIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon prev_track_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "path", {
      d: "M10 3.22l-.61-.6a5.5 5.5 0 0 0-7.78 7.77L10 18.78l8.39-8.4a5.5 5.5 0 0 0-7.78-7.77l-.61.61z"
    }

