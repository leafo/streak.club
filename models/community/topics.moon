
class Topics extends require "community.models.topics"
  url_params: (req, ...) =>
    if @slug and @slug != ""
      "community.topic", { topic_id: @id, topic_slug: @slug }, ...
    else
      "community.topic", { topic_id: @id }, ...

  name_for_display: =>
    @title or "anonymous topic"

  is_single_page: =>
    import POSTS_PER_PAGE from require "community.limits"
    @root_posts_count <= POSTS_PER_PAGE

  last_page_url_params: =>
    route, params, query = @url_params!
    unless @is_single_page!
      query or= {}
      query.after = nil
      query.before = @root_posts_count + 1

    route, params, query

  latest_post_url_params: (r, ...) =>
    route, params, get = @url_params r, ...
    get or= {}
    get.before = @find_latest_root_post!.post_number + 1
    get.after = nil
    route, params, get
