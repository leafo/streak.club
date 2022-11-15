
export class InfiniteScroll
  loading_element: ".list_loader"

  constructor: (el, opts={}) ->
    @el = $ el
    $.extend @, opts
    @setup_loading()

  get_next_page: ->
    alert "override me"

  setup_loading: ->
    @loading_row = @el.find @loading_element
    return unless @loading_row.length

    win = $(window)
    check_scroll_pos = =>
      return if @el.is ".loading"
      if win.scrollTop() + win.height() >= @loading_row.offset().top
        @get_next_page()

    check_scroll_pos = _.throttle check_scroll_pos, 100

    win.on "scroll.browse_loader", check_scroll_pos
    _.defer => check_scroll_pos()

  remove_loader: ->
    $(window).off "scroll.browse_loader"
    @loading_row.remove()

