import {createElement} from 'react'


export ArrowUpIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon arrow_up_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "polygon", points: "9 3.828 2.929 9.899 1.515 8.485 10 0 10.707 .707 18.485 8.485 17.071 9.899 11 3.828 11 20 9 20 9 3.828"

export ArrowDownIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon arrow_down_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "polygon", points: "9 16.172 2.929 10.101 1.515 11.515 10 20 10.707 19.293 18.485 11.515 17.071 10.101 11 16.172 11 0 9 0"


export DownloadIcon = (props={}) ->
  createElement "svg", {
    className: "icon svgicon download_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "20"
    height: props.height ? "20"
    viewBox: "0 0 20 20"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    createElement "path", d: "M13 8V2H7v6H2l8 8 8-8h-5zM0 18h20v2H0v-2z"

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

