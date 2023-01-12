
import {with_csrf} from "main/_pre"
import {jstz} from "main/global_libs"
import $ from "main/jquery"

export class Flasher
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

export class Header
  constructor: (el, @opts) ->
    @setup_flash()
    el = $(el).dispatch "click", {
      menu_button: (el) =>
        el.closest(".menu_wrapper").toggleClass "open"
    }

    $(document.body).click (e) =>
      return if $(e.target).closest(".menu_wrapper").length
      el.find(".menu_wrapper").removeClass "open"

  setup_flash: =>
    return unless @opts.flash
    flash = @opts.flash

    @flasher ||= new Flasher
    type = "notice"

    if flash.match /^error:/
      flash = flash.replace /^error:/, "Error: "
      type = "error"

    @flasher.show type, flash

export class Timezone
  save_timezone: (timezone) ->
    $.post @params.tz_url, with_csrf(timezone: timezone)

  constructor: (@params) ->
    timezone = jstz.determine().name()
    if timezone != @params.last_timezone
      @save_timezone timezone
