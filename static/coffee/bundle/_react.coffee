
EMPTY = {}
is_different = (a, b) ->
  for own key of a
    return true if a[key] != b[key]

  for own key of b
    return true unless key of a

  false

window.R = (name, data, p=R, prefix="") ->
  data.trigger = ->
    R.trigger @, arguments...
    undefined

  data.dispatch = ->
    R.dispatch @, arguments...
    undefined

  if data.pure
    data.shouldComponentUpdate = (nextProps, nextState) ->
      is_different(@props || EMPTY, nextProps) || is_different(@state || EMPTY , nextState)

  data.displayName = "R.#{prefix}#{name}"

  default_props = data.getDefaultProps
  delete data.getDefaultProps

  cl = createReactClass(data)
  cl.defaultProps = default_props

  p[name] = React.createFactory(cl)
  p[name]._class = cl

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
