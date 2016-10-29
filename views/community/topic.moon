
TopicPosts = require "widgets.community.topic_posts"

class CommunityTopic extends require "widgets.page"
  inner_content: =>
    div class: "responsive_column", ->
      widget TopicPosts {}
