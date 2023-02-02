import {R, fragment, classNames} from "./_react"
import * as React from 'react'
import * as ReactDOM from 'react-dom'

import {div} from 'react-dom-factories'

export default class VideoPlayer extends React.Component
  constructor: (props) ->
    super props
    @state = {
      loaded: false
    }

  render: ->
    div className: "submission_video_widget",
      "Hello world"

