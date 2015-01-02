
class S.Flasher
  duration: 10000
  animation_duration: 250
  clipping: "-7px"

  constructor: ->
    $(document).on "click", ".global_flash", =>
      @dismiss()

  dismiss: ->
    if elm = @current_flash
      if @timeout
        clearTimeout @timeout
        @timeout = null

      elm.css "margin-top": "-#{elm.outerHeight() + 4}px"
      setTimeout (=> elm.remove()), @animation_duration * 2

  show: (type, msg) ->
    console.log "showing flash", type, msg
    @dismiss()
    elm = $("<div class='global_flash #{type}'>")
      .text(msg).appendTo("body")

    elm.css {
      "margin-left": "-#{elm.width()/2}px"
      "margin-top": "-#{elm.outerHeight() + 4}px"
    }

    @timeout = setTimeout =>
      elm.addClass "animated"
      elm.css "margin-top": @clipping
      setTimeout (=> @dismiss()), @duration
    , 100

    @current_flash = elm

class S.Header
  constructor: (el, @opts) ->
    @setup_flash()

  setup_flash: =>
    return unless @opts.flash
    flash = @opts.flash

    @flasher ||= new S.Flasher
    type = "notice"

    if flash.match /^error:/
      flash = flash.replace /^error:/, "Error: "
      type = "error"

    @flasher.show type, flash

