import {R, fragment, classNames} from "./_react"

P = R.package "ReferenceSession"

import {div, button, span} from 'react-dom-factories'

import $ from "main/jquery"
import {with_csrf} from "main/util"

export ReferenceSession = P "ReferenceSession", {
  fetch_state: ->
    $.post("", with_csrf())
      .always =>
        setTimeout @fetch_state, 2000

      .then (res) =>
        if res.state
          @setState res.state

  componentDidMount: ->
    @fetch_state()

  pick_upload: =>

  render: ->
    div {
      className: "empty_display"
    },
      button {
        className: "button"
        onClick: @pick_upload
      }, "Upload image"

      span {}, "Paste or drop image to share it"
}
