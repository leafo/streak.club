import $ from "main/jquery"
import S from "main/_pre"

export class FollowingFeed
  constructor: (el) ->
    @el = $ el
    @el.has_tooltips()
    S.has_follow_buttons @el

