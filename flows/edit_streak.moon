
date = require "date"

import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"
import filter_update from require "helpers.model"

import Flow from require "lapis.flow"

class EditStreakFlow extends Flow
  validate_params: =>
    assert_valid @params, {
      {"streak", type: "table"}
    }

    streak_params = @params.streak
    trim_filter streak_params, {
      "title", "description", "short_description", "start_date", "end_date"
    }

    assert_valid streak_params, {
      {"title", exists: true, max_length: 1024}
      {"short_description", exists: true, max_length: 1024 * 10}
      {"description", exists: true, max_length: 1024 * 10}
      {"start_date", exists: true, max_length: 1024}
      {"end_date", exists: true, max_length: 1024}
    }

    streak_params.rate = "daily"
    streak_params

  create_streak: =>
    import Streaks from require "models"

    params = @validate_params!
    streak_params.user_id = @current_user.id

    Streaks\create params

  edit_streak: =>
    import Streaks from require "models"

    assert @streak
    params = @validate_params!
    params.rate = Streaks.rates\for_db params.rate

    filter_update @streak, params
    if next params
      @streak\update params

