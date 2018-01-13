
UserHeader = require "widgets.user_header"

class UserTags extends require "widgets.page"
  @needs: {"user", "tags_by_frequency"}

  page_name: "tags"
  responsive: true

  inner_content: =>
    widget UserHeader page_name: @page_name
    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    if next @tags_by_frequency
      h3 "Most frequent tags used on #{@user\name_for_display!}'s submissions"
      ul class: "tag_list", ->
        for {:slug, :count} in *@tags_by_frequency
          li class: "tag", ->
            a href: @url_for("user_tag", slug: @user.slug, tag_slug: slug), ->
              span class: "tag_name", slug
              span class: "tag_count", @number_format count

    else
      div class: "inner_column", ->
        p class: "empty_message", "This person hasn't tagged any of their submissions yet"

