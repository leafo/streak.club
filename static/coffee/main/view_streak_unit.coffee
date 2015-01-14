
class S.ViewStreakUnit
  constructor: (el) ->
    @el = $ el
    @el.has_tooltips()
    S.format_dates @el, "format", "MMMM Do YYYY, h:mm:ss a"
