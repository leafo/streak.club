PostList = require "widgets.community.post_list"

class CommunityPost extends require "widgets.page"
  responsive: true
  column_content: =>
    form method: "post", class: "form", ->
      @csrf_input!
      input type: "hidden", name: "action", value: "delete"
      p ->
        text "Are you sure you want to delete this "
        strong @noun
        text "? "
        button class:"button", "Delete"

    widget PostList posts: { @post }
