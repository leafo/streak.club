
class S.ViewStreak
  constructor: (el, @streak) ->
    @el = $ el
    @el.has_tooltips()
    S.format_dates @el, "format", "MMMM Do YYYY, h a"

    @start = moment @streak.start
    @end = @streak.end && moment @streak.end
    @unit_start = moment @streak.unit_start
    @unit_end = moment @streak.unit_end

    @setup_countdown()
    @setup_leave()

    @el.on "click", ".streak_description .click_to_open_overlay", =>
      @el.find(".streak_description").addClass "description_unrolled"

  setup_countdown: ->
    countdown = @el.find ".countdown"
    return unless countdown.length
    countdown_time = if @streak.before_start
      @start
    else
      @unit_end

    new S.Countdown countdown, countdown_time

  setup_leave: ->
    leave_form = @el.find ".leave_form"
    leave_form.on "submit", =>
      confirm('Are you sure you want to leave this streak?')
