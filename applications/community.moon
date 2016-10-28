
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

      unless @streak.community_category_id
        @streak\create_default_category!
        @streak\refresh!

      @community_category = @streak\get_community_category!
      render: true
  }




