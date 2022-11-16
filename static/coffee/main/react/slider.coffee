import {R, classNames} from "./_react"
import * as React from 'react'
import {div, button, input} from 'react-dom-factories'

P = R.package "Forms"

export default P "Slider", {
  pure: true
  # propTypes: {
  #   min: types.number
  #   max: types.number
  #   value: types.number
  #   onChange: types.func
  #   disabled: types.bool
  # }

  getInitialState: -> {}

  on_change: (value) ->
    value = Math.round value

    if @props.onChange
      return if @props.value == value
      @props.onChange value
    else
      return if @state.value == value
      @setState value: value

  start_drag: (start_x, start_y) ->
    return if @props.disabled
    width = @track_ref.current?.clientWidth ? 0
    start_value = @current_value()
    @setState dragging: true

    move_listener = (e) =>
      e.preventDefault()
      if e.buttons == 0
        up_listener()
        return

      x = e.pageX
      y = e.pageX

      dx = x - start_x

      new_value = dx / width * (@props.max - @props.min) + start_value
      new_value = Math.min @props.max, Math.max @props.min, new_value

      unless new_value == @current_value()
        @on_change new_value

    up_listener = (e) =>
      e?.preventDefault()
      @setState dragging: false
      document.body.removeEventListener "mousemove", move_listener
      document.body.removeEventListener "mouseup", up_listener
      delete @up_listener

    document.body.addEventListener "mousemove", move_listener
    document.body.addEventListener "mouseup", up_listener

    @up_listener = up_listener

  current_value: ->
    if "value" of @state
      @state.value || @props.min
    else
      @props.value || @props.min

  percent: ->
    (@current_value() - @props.min) / (@props.max - @props.min)

  componentWillUnmount: ->
    if @up_listener
      @up_listener()

  render: ->
    offset_style = {
      left: @percent() * 100 + "%"
    }

    div {
      className: classNames "slider_input", disabled: @props.disabled
      onClick: (e) =>
        return if e.target == @slider_nub_ref.current

        rect = @track_ref.current?.getBoundingClientRect()
        return unless rect

        p = Math.min(rect.width, Math.max(0, e.pageX - rect.left)) / rect.width

        new_value = @props.min + p * (@props.max - @props.min)
        new_value = Math.min(@props.max, Math.max(@props.min, new_value))

        if new_value != @current_value()
          @on_change new_value
    },
      if @props.name
        input type: "hidden", name: @props.name, value: @current_value()

      div {
        ref: @track_ref ||= React.createRef()
        className: "slider_track"
      },
        div className: "slider_fill", style: { width: @percent() * 100 + "%" }

        if @state.focused && @props.show_tooltip
          div style: offset_style, className: "value_tooltip", @current_value()

        button {
          type: "button"
          ref: @slider_nub_ref ||= React.createRef()
          className: "slider_nub"
          onFocus: =>
            @setState focused: true

          onBlur: =>
            @setState focused: false

          onMouseDown: (e) =>
            e.preventDefault()
            @start_drag e.pageX, e.pageY

          onKeyDown: (e) =>
            switch e.keyCode
              when 37 # left
                @on_change Math.max @props.min, @current_value() - 1
              when 39 # right
                @on_change Math.min @props.max, @current_value() + 1
              else
                return

            e.preventDefault()

          style: offset_style
        }
}

