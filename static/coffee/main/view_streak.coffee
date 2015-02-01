
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
    @setup_sticky()

    recalc = _.throttle =>
      $(document.body).trigger "sticky_kit:recalc"
    , 50

    @el.find(".submission_upload img").load recalc
    @el.on "s:reshape", recalc

  setup_sticky: =>
    to_stick = @el.find(".streak_side_column")

    sticky_kit_on = false
    win = $ window
    update = =>
      if win.width() >= 960
        unless sticky_kit_on
          to_stick.stick_in_parent {
            offset_top: 25 + 50 # header height
            recalc_every: 2
          }
          sticky_kit_on = true
      else
        if sticky_kit_on
          sticky_kit_on = false
          to_stick.trigger "sticky_kit:detach"

    update()
    win.on "resize", _.throttle update, 100

  setup_countdown: ->
    countdown = @el.find ".countdown"
    return unless countdown.length
    countdown_time = if @streak.before_start
      @start
    else
      @unit_end

    new S.Countdown countdown, countdown_time

