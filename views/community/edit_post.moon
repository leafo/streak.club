import Topics, Posts from require "community.models"

import to_json from require "lapis.util"

PostForm = require "widgets.community.post_form"

class CommunityEditPost extends require "widgets.page"
  column_content: =>
    widget PostForm {}
