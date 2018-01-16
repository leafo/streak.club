StreakHeader = require "widgets.streak_header"

TopicList = require "widgets.community.topic_list"

class CommunityStreak extends require "widgets.page"
  page_name: "community"

  inner_content: =>
    widget StreakHeader page_name: @page_name
    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    if next @topics
      widget TopicList {}
    else
      p class: "empty_message", "No topics yet"

    div class: "post_buttons", ->
      a {
        href: @url_for("community.new_topic", category_id: @category.id)
        class: "button"
      }, "New discussion"

