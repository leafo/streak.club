
lapis = require "lapis"

import respond_to from require "lapis.application"

class UsersApplication extends lapis.Application
  [user_register: "/register"]: respond_to {
    GET: => render: true
    POST: =>
  }

  [user_login: "/login"]: respond_to {
    GET: => render: true
    POST: =>
  }
