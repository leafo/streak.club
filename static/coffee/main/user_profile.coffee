
class S.UserProfile
  constructor: (el) ->
    @el = $ el
    @el.has_tooltips()
    S.has_follow_buttons @el

