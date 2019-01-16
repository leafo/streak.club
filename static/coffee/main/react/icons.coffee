P = R.package "Icons"

P.MenuIcon = (props={}) ->
  React.createElement "svg", {
    className: "icon svgicon menu_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "24"
    height: props.height ? "24"
    viewBox: "0 0 24 24"
    fill: "none"
    stroke: "currentColor"
    strokeWidth: "2"
    strokeLinecap: "round"
    strokeLinejoin: "round"
    "aria-hidden": true
  },
    React.createElement "line", {
      x1: "3", y1: "12", x2: "21", y2: "12"
    }
    React.createElement "line", {
      x1: "3", y1: "6", x2: "21", y2: "6"
    }
    React.createElement "line", {
      x1: "3", y1: "18", x2: "21", y2: "18"
    }

P.PlayIcon = (props={}) ->
  React.createElement "svg", {
    className: "icon svgicon play_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "25.666"
    height: props.height ? "22.227"
    viewBox: "0 0 20.838 24.061"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    React.createElement "path", {
      d: "M20.838 12.03L0 24.062V0z"
    }

P.PauseIcon = (props={}) ->
  React.createElement "svg", {
    className: "icon svgicon pause_icon"
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width ? "16.701"
    height: props.height ? "20.742"
    viewBox: "0 0 15.657 19.445"
    fill: "currentColor"
    stroke: "none"
    "aria-hidden": true
  },
    React.createElement "rect", {
      height: "19.445"
      ry: "2.652"
      width: "5.303"
    }

    React.createElement "rect", {
      height: "19.445"
      ry: "2.652"
      width: "5.303"
      x: "10.354"
    }

