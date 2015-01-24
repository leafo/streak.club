
class S.UserSettings
  constructor: (el) ->
    @el = $ el
    S.redactor @el.find "textarea"
