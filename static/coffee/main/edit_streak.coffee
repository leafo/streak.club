
class S.EditStreak
  constructor: (el, @opts={}) ->
    @el = $ el

    @el.find(".date_picker").datepicker()
