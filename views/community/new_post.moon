import Topics, Posts from require "community.models"

import to_json from require "lapis.util"

class CommunityNewPost extends require "widgets.page"
  column_content: =>
    text "what the heck"
