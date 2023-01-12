
import {has_follow_buttons} from "main/_pre"
import $ from "main/jquery"

export class UserList
  constructor: (el) ->
    @el = $ el
    has_follow_buttons @el
