
$.fn.has_tooltips = ->
  tooltip_drop = ->
    drop = $ '<div class="tooltip_drop"></div>'
    $(document.body).append drop
    tooltip_drop = -> drop
    drop


  tooltip_template = _.template """
  <div class="tooltip">{{ label }}</div>
  """

  show_tooltip = (tooltip_target, instant=false) ->
    el = tooltip_target.data "tooltip_el"
    unless el
      el = $ tooltip_template label: tooltip_target.data "tooltip"
      tooltip_target.data "tooltip_el", el

    el.removeClass "visible"
    tooltip_drop().empty().append el
    offset = tooltip_target.offset()

    height = el.outerHeight()
    width = el.outerWidth()

    el.css {
      position: "absolute"
      top: offset.top - height - 10
      left: Math.floor offset.left + (tooltip_target.outerWidth() - width) / 2
    }

    if instant
      el.addClass "visible"
    else
      setTimeout (=> el.addClass "visible"), 10

  @on "i:refresh_tooltip", "[data-tooltip]", (e) =>
    tooltip_target = $(e.currentTarget)
    el = tooltip_target.data "tooltip_el"
    tooltip_target.removeData "tooltip_el"

    if el.is ":visible"
      show_tooltip tooltip_target, true

  @on "mouseenter", "[data-tooltip]", (e) =>
    tooltip_target = $(e.currentTarget)
    show_tooltip tooltip_target

  @on "mouseleave i:hide_tooltip", "[data-tooltip]", (e) =>
    tooltip_target = $(e.currentTarget)
    if el = tooltip_target.data "tooltip_el"
      el.remove()

  @

