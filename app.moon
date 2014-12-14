lapis = require "lapis"

class extends lapis.Application
  layout: require "views.layout"

  "/": =>
    "Welcome to Lapis #{require "lapis.version"}!"
