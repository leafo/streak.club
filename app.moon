lapis = require "lapis"

class extends lapis.Application
  layout: require "views.layout"

  [index: "/"]: =>
    render: true
