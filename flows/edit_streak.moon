
date = require "date"

db = require "lapis.db"

import assert_error from require "lapis.application"
import assert_valid from require "lapis.validate"
import trim_filter from require "lapis.util"
import filter_update from require "helpers.model"
import assert_timezone from require "helpers.app"

import Flow from require "lapis.flow"
import Streaks from require "models"

class EditStreakFlow extends Flow
  validate_params: =>
    assert_valid @params, {
      {"streak", type: "table"}
    }

    streak_params = @params.streak
    trim_filter streak_params, {
      "title", "description", "short_description", "start_date", "end_date",
      "hour_offset", "publish_status"
    }

    assert_valid streak_params, {
      {"title", exists: true, max_length: 1024}
      {"short_description", exists: true, max_length: 1024 * 10}
      {"description", exists: true, max_length: 1024 * 10}
      {"start_date", exists: true, max_length: 1024}
      {"end_date", exists: true, max_length: 1024}
      {"hour_offset", exists: true}
      {"publish_status", one_of: Streaks.publish_statuses}
    }

    timezone = assert_timezone @params.timezone

    timezone_offset = tonumber timezone.utc_offset\match "^(-?%d+)"
    hour_offset = tonumber(streak_params.hour_offset) or 0

    assert_error hour_offset <= 12 and hour_offset >= -12,
      "hour offset must not be more than 12 hours"

    streak_params.hour_offset = timezone_offset - hour_offset

    start_date = date streak_params.start_date
    end_date = date streak_params.end_date

    assert_error start_date < end_date, "start date must be before end date"

    streak_params.rate = "daily"
    streak_params

  create_streak: =>
    params = @validate_params!
    params.user_id = @current_user.id

    streak = Streaks\create params

    @current_user\update {
      streaks_count: db.raw "streaks_count + 1"
    }

    streak

  edit_streak: =>
    assert @streak
    params = @validate_params!
    params.rate = Streaks.rates\for_db params.rate
    params.publish_status = Streaks.publish_statuses\for_db params.publish_status

    filter_update @streak, params

    if next params
      @streak\update params

