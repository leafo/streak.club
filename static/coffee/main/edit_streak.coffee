
class S.EditStreak
  constructor: (el, @opts={}) ->
    @el = $ el
    @el.find(".date_picker").datepicker()
    @setup_timezone()

    S.redactor @el.find "textarea"

    form = @el.find("form")
    form.remote_submit (res) =>
      if res.errors
        form.set_form_errors res.errors
        return

      if res.url
        window.location = res.url


  setup_timezone: =>
    @el.find(".timezone_input").val jstz.determine().name()

    tz_offset = new Date().getTimezoneOffset()/60
    console.log @opts.streak.hour_offset, tz_offset

    offset = if @opts.streak.hour_offset?
      -@opts.streak.hour_offset - tz_offset
    else
      0

    hour_offset_input = @el.find ".hour_offset_input"
    hour_offset_input.val offset

