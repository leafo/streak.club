lapis = require "lapis"

import Users from require "models"

class extends lapis.Application
  layout: require "views.layout"

  @include "applications.users"

  @before_filter =>
    @current_user = Users\read_session @

    if @session.flash
      @flash = @session.flash
      @session.flash = false

  [index: "/"]: =>
    render: true
