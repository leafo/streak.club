
S.support_passive_scroll = ->
  supports = false

  try
    opts = Object.defineProperty {}, "passive", {
      get: => supports = true
    }

    window.addEventListener "test", null, opts

  supports

S.support_intersection_observer = ->
  "IntersectionObserver" of window

show_images = (item, make_promise) ->
  item.removeClass "lazy_images"
  cells = item.find("[data-background_image]").addBack "[data-background_image]"

  images = for cell in cells
    do (cell) ->
      cell = $ cell
      image_url = cell.data "background_image"

      cell.css backgroundImage: "url(#{image_url})"

      if make_promise
        $.Deferred (d) =>
          $("<img />").attr("src", image_url).on "load", =>
            d.resolve()

  for img in item.find("img[data-lazy_src]").addBack("img[data-lazy_src]")
    do (img) ->
      img = $ img
      image_url = img.data "lazy_src"
      img.attr "src", image_url
      if srcset = img.data "lazy_srcset"
        img.attr "srcset", srcset

      if make_promise
        $.Deferred (d) =>
          img.on "load", => d.resolve()

  if make_promise
    if images.length == 1
      images[0]
    else
      $.when images...

$.fn.lazy_images = (opts) ->
  if refresh = @data "lazy_images"
    # calling again? Just refresh the current images
    return refresh()

  lazy = if opts?.elements
    ($(el) for el in opts.elements)
  else
    selector = opts?.selector || ".lazy_images"
    ($(el) for el in @find selector)

  _show_images = opts?.show_images ? show_images

  if S.support_intersection_observer()
    handle_intersect = (entities) ->
      for entity in entities
        if entity.isIntersecting
          el = entity.target
          io.unobserve el
          # show images
          el = $ el
          on_show = opts?.show_item
          d = _show_images el, !!on_show
          on_show? el, d

    io = new IntersectionObserver handle_intersect, { }

    for el in lazy
      io.observe el[0]

    return ->
      io.disconnect()

  # legacy lazy loading here
  console.warn "setting up legazy lazy image loader"
  win = $ window

  target = opts?.target
  horizontal = opts?.horizontal
  unbind = null

  check_images = =>
    cuttoff = if target
      if horizontal
        target.outerWidth() + target.position().left
      else
        throw new Error "not yet"
    else
      win.scrollTop() + win.height()

    found = 0
    for item, i in lazy
      continue unless item

      # removed from dom
      unless document.body.contains(item[0])
        lazy[i] = null
        found += 1
        continue

      position = if target
        if horizontal
          item.position().left
        else
          throw new Error "not yet"
      else
        item.offset().top

      # image is display none
      continue unless item[0].offsetParent

      if position < cuttoff
        on_show = opts?.show_item
        d = _show_images item, !!on_show
        on_show? item, d

        found += 1
        lazy[i] = null

    if found > 0
      lazy = (el for el in lazy when el)

  throttled = _.throttle check_images, 100

  if target
    target.on "scroll", throttled
    win.on "resize", throttled

    unbind = ->
      target.off "scroll", throttled
      win.off "resize", "throttled"
  else
    if S.support_passive_scroll()
      window.addEventListener "scroll", throttled, passive: true
      win.on "resize", throttled

      unbind = ->
        window.removeEventListener "scroll", throttled, passive: true
        win.off "resize", throttled

    else
      win.on "scroll resize", throttled

      unbind = ->
        win.off "scroll resize", throttled

  @data "lazy_images", =>
    lazy = if opts?.elements
      ($(el) for el in opts.elements)
    else
      selector = opts?.selector || ".lazy_images"
      ($(el) for el in @find selector)

    check_images()

  check_images()

  unbind

