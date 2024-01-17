PostList = require "widgets.community.post_list"

class CommunityPost extends require "widgets.page"
  responsive: true
  column_content: =>
    form method: "post", class: "form", ->
      @csrf_input!

      input type: "hidden", name: "action", value: "delete"
      if @post.deleted
        input type: "hidden", name: "hard", value: "true"

      p ->
        text "Are you sure you want to delete this "
        strong @noun
        text "? "
        if @post.deleted
          button class:"button", "Purge"
        else
          button class:"button", "Delete"

    br!
    br!
    widget PostList posts: { @post }
