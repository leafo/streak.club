
UserHeader = require "widgets.user_header"

class UserFollowers extends require "widgets.page"
  @needs: {"user", "tags_by_frequency"}

  page_name: "tags"

  inner_content: =>
    widget UserHeader page_name: @page_name
    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    div class: "base_widget", ->
      if next @tags_by_frequency
        element "table", class: "nice_table", ->
          thead ->
            tr ->
              td "Tag"
              td "Frequency"

          for {:slug, :count} in *@tags_by_frequency
            tr ->
              td ->
                a href: @url_for("user_tag", slug: @user.slug, tag_slug: slug), slug
              td @number_format count

      else
        p class: "empty_message", "This person hasn't tagged any of their submissions yet"

