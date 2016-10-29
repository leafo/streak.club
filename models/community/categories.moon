
class Categories extends require "community.models.categories"
  @relations: {
    {"streak", has_one: "Streaks"}
  }

  edit_options: =>
    {}

  url_params: =>
    streak = @get_streak!
    "community.streak", id: @streak.id, slug: @streak\slug!

