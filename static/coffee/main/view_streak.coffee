
class S.ViewStreak
  constructor: (el, @streak) ->
    @el = $ el
    @el.has_tooltips()
    S.format_dates @el

    @setup_countdown()
    @setup_leave()

    @el.on "click", ".streak_description .click_to_open_overlay", =>
      @el.find(".streak_description").addClass "description_unrolled"

  setup_countdown: ->
    countdown = @el.find ".countdown"
    return unless countdown.length

    countdown_to = if @streak.before_start
      @streak.start
    else
      @streak.unit_end

    new S.Countdown countdown, countdown_to

  setup_leave: ->
    leave_form = @el.find ".leave_form"
    leave_form.on "submit", =>
      confirm('Are you sure you want to leave this streak?')
