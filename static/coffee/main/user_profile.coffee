
import $ from "main/jquery"
import {has_follow_buttons} from "main/_pre"

export class UserProfile
  constructor: (el) ->
    @el = $ el
    @el.has_tooltips()
    has_follow_buttons @el

