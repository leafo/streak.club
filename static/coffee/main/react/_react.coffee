
import * as React from 'react'
import * as ReactDOM from 'react-dom'

import createReactClass from "create-react-class"

export fragment = React.createElement.bind null, React.Fragment
fragment.type = React.fragment

import $ from "main/jquery"

import cn from "classnames"
export classNames = cn

EMPTY = {}
is_different = (a, b) ->
  for own key of a
    return true if a[key] != b[key]

  for own key of b
    return true unless key of a

  false

export R = (name, data, p=R, prefix="") ->
  data.trigger = ->
    R.trigger @, arguments...
    undefined

  data.dispatch = ->
    R.dispatch @, arguments...
    undefined

  if data.pure
    data.shouldComponentUpdate = (nextProps, nextState) ->
      is_different(@props || EMPTY, nextProps) || is_different(@state || EMPTY , nextState)

  data.displayName = "#{prefix}#{name}"

  default_props = data.getDefaultProps
  delete data.getDefaultProps

  prop_types = data.propTypes
  delete data.propTypes

  cl = createReactClass(data)
  if default_props
    cl.defaultProps = default_props()

  if prop_types
    cl.propTypes = prop_types

  # create the factory -> a function that returns result of React createElement
  # this is so we don't have to use createElement whenever we want to insert
  # out custom components
  factory = React.createElement.bind null, cl
  factory.type = cl
  p[name] = factory


R.scope_event_name = (name) ->
  "streak:#{name}"

R.trigger = (c, name, args...) ->
  $(ReactDOM.findDOMNode(c)).trigger R.scope_event_name(name), [args...]

R.dispatch = (c, prefix, event_table) ->
  node = $ ReactDOM.findDOMNode(c)

  if typeof(prefix) == "object"
    event_table = prefix
    prefix = false

  for own event_name, fn of event_table
    if prefix
      event_name = "#{prefix}:#{event_name}"

    node.on R.scope_event_name(event_name), fn

R.component = -> R arguments...

R.package = (prefix) =>
  p = R[prefix] ||= (name, data) ->
    data.Package = p
    R.component name, data, p, "#{prefix}."

  p.component = -> p arguments...
  p

window.ReactDOM = ReactDOM
window.React = React
window.R = R
