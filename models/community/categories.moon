
class Categories extends require "community.models.categories"
  @get_relation_model: (name) =>
    require("models")[name] or @__parent\get_relation_model name

  @relations: {
    {"streak", has_one: "Streaks", key: "community_category_id"}
  }

  edit_options: =>
    {}

  url_params: =>
    streak = @get_streak!
    "community.streak", id: @streak.id, slug: @streak\slug!

  name_for_display: =>
    return @title if @title
    streak = @get_streak!
    if streak
      @streak.title .. " discussion"
    else
      "unnamed community"




