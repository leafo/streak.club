
import $ from "main/jquery"

import {jstz} from "main/global_libs"

export class EditStreak
  constructor: (el, @opts={}) ->
    @el = $ el
    # TODO: datepicker must be handled
    @el.find(".date_picker").datepicker()
    @setup_timezone()

    form = @el.find("form")
    form.remote_submit (res) =>
      if res.errors
        form.set_form_errors res.errors
        return

      if res.url
        window.location = res.url

    end_input = form.find("input.end_date")

    update_end_input = ->
      end_input.prop "disabled", toggle_input.is(":checked")

    toggle_input = form.find(".end_date_toggle_input").on "change", (e) ->
      update_end_input()

    update_end_input()

  setup_timezone: =>
    @el.find(".timezone_input").val jstz.determine().name()

    tz_offset = new Date().getTimezoneOffset()/60

    offset = if @opts.streak.hour_offset?
      -@opts.streak.hour_offset - tz_offset
    else
      0

    hour_offset_input = @el.find ".hour_offset_input"
    hour_offset_input.val offset

