
import $ from "main/jquery"
import dayjs from "main/dayjs"

export class Countdown
  constructor: (el, date) ->
    @el = $ el
    parts = ["days", "hours", "minutes", "seconds"]

    update_countdown = =>
      dur = dayjs.duration dayjs(date).diff dayjs()

      can_hide = true

      for p in parts
        p_el = @el.find "[data-name='#{p}']"
        val = dur[p]()

        p_el
          .toggleClass("hidden", can_hide && val == 0)
          .find(".block_value").text(val)

        can_hide = can_hide && val == 0

    update_countdown()
    window.setInterval update_countdown, 1000


