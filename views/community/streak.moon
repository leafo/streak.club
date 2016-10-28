StreakHeader = require "widgets.streak_header"

TopicList = require "widgets.community.topic_list"

class StreakCommunity extends require "widgets.page"
  page_name: "community"

  inner_content: =>
    widget StreakHeader page_name: @page_name
    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    widget TopicList

    p ->
      a href: @url_for("community.new_topic", category_id: @category.id), "New topic"

