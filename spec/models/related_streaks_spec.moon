import use_test_env from require "lapis.spec"

factory = require "spec.factory"

describe "models.related_streaks", ->
  use_test_env!

  import Streaks, Users, RelatedStreaks from require "spec.models"

  it "creates a related streak", ->
    a = factory.Streaks!
    b = factory.Streaks!

    assert RelatedStreaks\create {
      streak_id: a.id
      other_streak_id: a.id
      type: "related"
    }

  it "gets empty related streaks", ->
    a = factory.Streaks!
    a\get_related_streaks!
    a\get_other_related_streaks!
