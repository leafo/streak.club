
date = require "date"

import assert_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"
import filter_update from require "helpers.model"
import assert_timezone from require "helpers.app"

import Flow from require "lapis.flow"

class EditStreakFlow extends Flow
  validate_params: =>
    assert_valid @params, {
      {"streak", type: "table"}
    }

    streak_params = @params.streak
    trim_filter streak_params, {
      "title", "description", "short_description", "start_date", "end_date", "hour_offset"
    }

    assert_valid streak_params, {
      {"title", exists: true, max_length: 1024}
      {"short_description", exists: true, max_length: 1024 * 10}
      {"description", exists: true, max_length: 1024 * 10}
      {"start_date", exists: true, max_length: 1024}
      {"end_date", exists: true, max_length: 1024}
      {"hour_offset", exists: true}
    }

    timezone = assert_timezone @params.timezone

    timezone_offset = tonumber timezone.utc_offset\match "^(-?%d+)"
    hour_offset = tonumber(streak_params.hour_offset) or 0

    streak_params.hour_offset = timezone_offset + hour_offset

    start_date = date streak_params.start_date
    end_date = date streak_params.end_date

    assert_error start_date < end_date, "start date must be before end date"

    streak_params.rate = "daily"
    streak_params

  create_streak: =>
    import Streaks from require "models"

    params = @validate_params!
    params.user_id = @current_user.id

    Streaks\create params

  edit_streak: =>
    import Streaks from require "models"

    assert @streak
    params = @validate_params!
    params.rate = Streaks.rates\for_db params.rate

    filter_update @streak, params
    if next params
      @streak\update params

