
lapis = require "lapis"

import
  respond_to
  capture_errors
  capture_errors_json
  from require "lapis.application"

class CommunityApplication extends lapis.Application
  [streak_community: "/s/:id/:slug/discussion"]: capture_errors {
    on_error: => not_found

    =>
      @flow("streak")\load_streak!
      "cool"
  }




