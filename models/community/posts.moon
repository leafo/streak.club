
db = require "lapis.db"

class Posts extends require "community.models.posts"
  url_params: =>
    if @is_topic_post! and not @get_topic!.permanent
      @get_topic!\url_params!
    else
      "community.post", post_id: @id




