lapis = require "lapis"

import Users from require "models"

class extends lapis.Application
  layout: require "views.layout"

  @include "applications.users"
  @include "applications.streaks"

  @before_filter =>
    @current_user = Users\read_session @

    if @current_user
      @current_user\update_last_active!

    if @session.flash
      @flash = @session.flash
      @session.flash = false

  [index: "/"]: =>
    render: true
