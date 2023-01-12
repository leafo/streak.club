
import $ from "main/jquery"
import {has_follow_buttons} from "main/util"

export class UserProfile
  constructor: (el) ->
    @el = $ el
    @el.has_tooltips()
    has_follow_buttons @el

