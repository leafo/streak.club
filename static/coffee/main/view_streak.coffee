
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
      $(document.body).trigger "sticky_kit:recalc"
    , 50

    @el.find(".submission_upload img").load recalc
    @el.on "s:reshape", recalc

  setup_countdown: ->
    countdown = @el.find ".countdown"
    return unless countdown.length
    new S.Countdown countdown, @unit_end

