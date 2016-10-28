
class Topics extends require "community.models.topics"
  url_params: (req, ...) =>
    if @slug and @slug != ""
      "community.topic", { topic_id: @id, topic_slug: @slug }, ...
    else
      "community.topic", { topic_id: @id }, ...


