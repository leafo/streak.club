import Request from require "lapis.application"

class R extends Request
  admin_url_for: (object, ...) =>
    if object.admin_url_params
      @url_for object\admin_url_params @, ...
    else
      error "object does not implement admin_url_params"

