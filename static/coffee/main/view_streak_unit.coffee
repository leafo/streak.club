
import $ from "main/jquery"

export class ViewStreakUnit
  constructor: (el) ->
    @el = $ el
    @el.has_tooltips()
