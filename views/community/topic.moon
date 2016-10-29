
TopicPosts = require "widgets.community.topic_posts"

class CommunityTopic extends require "widgets.page"
  column_content: =>
    widget TopicPosts {}
