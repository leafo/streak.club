
class S.ViewStreak
  constructor: (el, @streak) ->
    @el = $ el
    @el.has_tooltips()
    S.format_dates @el, "format", "MMMM Do YYYY, h:mm:ss a"

    @start = moment @streak.start
    @end = moment @streak.start
    @unit_start = moment @streak.unit_start
    @unit_end = moment @streak.unit_end

    @setup_countdown()

  setup_countdown: ->
    countdown = @el.find ".countdown"
    parts = ["days", "hours", "minutes", "seconds"]

    update_countdown = =>
      dur = moment.duration @unit_end.diff moment()
      console.log dur.days(), dur.hours(), dur.minutes(), dur.seconds()
      can_hide = true

      for p in parts
        p_el = countdown.find "[data-name='#{p}']"
        val = dur[p]()
        val = 0 if p == "minutes"
        console.log p, val, can_hide

        p_el
          .toggleClass("hidden", can_hide && val == 0)
          .find(".block_value").text(val)

        can_hide = can_hide && val == 0

    update_countdown()
    window.setInterval update_countdown, 1000


