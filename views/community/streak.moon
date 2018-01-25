StreakHeader = require "widgets.streak_header"

TopicList = require "widgets.community.topic_list"

class CommunityStreak extends require "widgets.page"
  page_name: "community"
  responsive: true

  inner_content: =>
    widget StreakHeader page_name: @page_name
    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    if next @topics
      @render_post_buttons "top"
      widget TopicList {}
    else
      p class: "empty_message", "No topics yet"

    @render_post_buttons!

  render_post_buttons: (cls)=>
    div class: {"post_buttons", cls}, ->
      a {
        href: @url_for("community.new_topic", category_id: @category.id)
        class: "button"
      }, "New discussion"

