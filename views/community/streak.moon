StreakHeader = require "widgets.streak_header"

class StreakCommunity extends require "widgets.page"
  page_name: "community"

  inner_content: =>
    widget StreakHeader page_name: @page_name
    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    p ->
      a href: @url_for("community.new_topic", category_id: @category.id), "New topic"

