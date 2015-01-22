lapis = require "lapis"

import Users from require "models"
import generate_csrf from require "helpers.csrf"

date = require "date"
config = require("lapis.config").get!

class extends lapis.Application
  layout: require "views.layout"

  cookie_attributes: =>
    expires = date(true)\adddays(365)\fmt "${http}"
    "Expires=#{expires}; Path=/; HttpOnly"

  @enable "exception_tracking"

  @include "applications.users"
  @include "applications.streaks"
  @include "applications.submissions"
  @include "applications.uploads"

  @before_filter =>
    @current_user = Users\read_session @
    generate_csrf @

    if @current_user
      @current_user\update_last_active!

    if @session.flash
      @flash = @session.flash
      @session.flash = false

  [index: "/"]: =>
    if @current_user
      @created_streaks = @current_user\get_created_streaks!
      @active_streaks = @current_user\get_active_streaks!

      Users\include_in @created_streaks, "user_id"
      Users\include_in @active_streaks, "user_id"
      render: "index_logged_in"
    else
      @mobile_friendly = true
      render: "index_logged_out"

  [terms: "/terms"]: =>
