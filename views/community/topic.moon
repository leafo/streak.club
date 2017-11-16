
TopicPosts = require "widgets.community.topic_posts"
StreakHeader = require "widgets.streak_header"

class CommunityTopic extends require "widgets.page"
  page_name: "community"

  js_init: =>

  inner_content: =>
    widget StreakHeader page_name: @page_name
    div class: "inner_column", ->
      @column_content!

  column_content: =>
    div class: "topic_header", ->
      h2 @topic.title

    widget TopicPosts {}
