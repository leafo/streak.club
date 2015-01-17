
class S.ViewStreak
  constructor: (el, @streak) ->
    @el = $ el
    @el.has_tooltips()
    S.format_dates @el, "format", "MMMM Do YYYY, h a"

    @start = moment @streak.start
    @end = moment @streak.start
    @unit_start = moment @streak.unit_start
    @unit_end = moment @streak.unit_end

    @setup_countdown()

    @el.find(".streak_side_column").stick_in_parent offset_top: 25

    recalc = _.throttle =>
      console.log "recalc sticky"
      $(document.body).trigger "sticky_kit:recalc"
    , 50

    @el.find(".submission_upload img").load recalc

  setup_countdown: ->
    countdown = @el.find ".countdown"
    return unless countdown.length

    parts = ["days", "hours", "minutes", "seconds"]

    update_countdown = =>
      dur = moment.duration @unit_end.diff moment()
      can_hide = true

      for p in parts
        p_el = countdown.find "[data-name='#{p}']"
        val = dur[p]()

        p_el
          .toggleClass("hidden", can_hide && val == 0)
          .find(".block_value").text(val)

        can_hide = can_hide && val == 0

    update_countdown()
    window.setInterval update_countdown, 1000


