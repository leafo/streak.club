import Topics, Posts from require "community.models"

import to_json from require "lapis.util"

PostForm = require "widgets.community.post_form"
PostList = require "widgets.community.post_list"

class CommunityEditPost extends require "widgets.page"
  column_content: =>
    h2 ->
      if @editing
        if @post\is_topic_post! and not @topic.permanent
          text "Editing topic"
        else
          text "Editing post"
      else
        if @parent_post
          parent_user = @parent_post\get_user!
          text "Replying to a post by "
          a target: "_blank", href: @url_for(parent_user), parent_user\name_for_display!
        else
          text "New reply"

    widget PostForm {}

    parents = @parent_posts or { @parent_post }
    if next parents
      div class: "parent_post", ->
        h3 "Replying to"
        widget PostList posts: parents
