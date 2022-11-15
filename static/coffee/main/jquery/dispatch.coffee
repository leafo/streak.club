export default $.fn.dispatch = (event_type, selector, table) ->
  if $.isPlainObject selector
    table = selector
    selector = undefined

  handler = (e) =>
    for key, fn of table
      elm = $(e.target).closest ".#{key}"
      continue unless elm.length
      if elm.is ".disabled"
        e.preventDefault()
        return

      res = fn elm, e
      unless res == "continue"
        e.preventDefault()
        return
    null

  if selector
    @on event_type, selector, handler
  else
    @on event_type, handler
