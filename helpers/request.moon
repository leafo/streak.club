config = require("lapis.config").get!

import Request from require "lapis.application"

class R extends Request
  @support: {
    default_url_params: =>
      if config.enable_https
        {
          host: config.host
          port: config.ssl_port
          scheme: "https"
        }
      else
        {
          host: config.host
          scheme: "http"
        }
  }

  admin_url_for: (object, ...) =>
    if object.admin_url_params
      @url_for object\admin_url_params @, ...
    else
      error "object does not implement admin_url_params"

