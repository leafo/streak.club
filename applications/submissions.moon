
lapis = require "lapis"

class UsersApplication extends lapis.Application
  [view_submission: "/submission/:id"]: =>
    "ok"
