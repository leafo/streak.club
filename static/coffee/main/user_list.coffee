
import {S} from "main/_pre"
import $ from "main/jquery"

export class UserList
  constructor: (el) ->
    @el = $ el
    S.has_follow_buttons @el
