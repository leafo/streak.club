
lapis = require "lapis"

import respond_to from require "lapis.application"
import require_login from require "helpers.app"

class UsersApplication extends lapis.Application
  [new_streak: "/streaks/new"]: require_login respond_to {
    GET: =>
      render: "edit_streak"
  }


