PostList = require "widgets.community.post_list"

class CommunityPost extends require "widgets.page"
  column_content: =>
    topic = @post\get_topic!

    p class: "topic_return_link", ->
      a href: @url_for(topic), ->
        text "Return to topic "
        strong topic\name_for_display!

    widget PostList posts: { @post }
