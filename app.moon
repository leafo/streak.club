lapis = require "lapis"

class extends lapis.Application
  layout: require "views.layout"

  @include "applications.users"

  [index: "/"]: =>
    render: true
