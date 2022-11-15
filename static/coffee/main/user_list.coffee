
import {S} from "main/_pre"

export class UserList
  constructor: (el) ->
    @el = $ el
    S.has_follow_buttons @el
