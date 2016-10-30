import use_test_env from require "lapis.spec"

factory = require "spec.factory"

describe "models.categories", ->
  use_test_env!

  import Users, Streaks from require "spec.models"

  it "it creates default category", ->
    streak = factory.Streaks!
    category = streak\create_default_category!
    assert.truthy category
    streak\refresh!
    assert.same streak.community_category_id, category.id

    streak\get_community_category!




