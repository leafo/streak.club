PostList = require "widgets.community.post_list"

class CommunityPost extends require "widgets.page"
  column_content: =>
    widget PostList posts: { @post }
