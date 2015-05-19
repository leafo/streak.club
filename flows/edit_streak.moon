
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
      "hour_offset", "publish_status", "rate", "category", "twitter_hash",
      "late_submit_type", "membership_type"
    }

    assert_valid streak_params, {
      {"title", exists: true, max_length: 1024}
      {"short_description", exists: true, max_length: 1024 * 10}
      {"description", exists: true, max_length: 1024 * 10}
      {"start_date", exists: true, max_length: 1024}
      {"end_date", exists: true, max_length: 1024}
      {"hour_offset", exists: true}
      {"publish_status", one_of: Streaks.publish_statuses}
      {"category", one_of: Streaks.categories}
      {"membership_type", one_of: Streaks.membership_types}
      {"rate", one_of: Streaks.rates}
      {"late_submit_type", one_of: Streaks.late_submit_types}
      {"twitter_hash", optional: true, max_length: 139}
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

    if h = streak_params.twitter_hash
      h = h\gsub "%s", ""
      h = h\gsub "#", ""
      h = nil if #h == 0
      streak_params.twitter_hash = h

    streak_params.twitter_hash or= db.NULL

    streak_params

  create_streak: =>
    params = @validate_params!
    params.user_id = @current_user.id

    streak = Streaks\create params

    @current_user\update {
      streaks_count: db.raw "streaks_count + 1"
      hidden_streaks_count: if streak\is_hidden! or streak\is_draft!
        db.raw "hidden_streaks_count + 1"
    }

    streak

  edit_streak: =>
    assert @streak
    params = @validate_params!

    params.rate = Streaks.rates\for_db params.rate
    params.publish_status = Streaks.publish_statuses\for_db params.publish_status
    params.category = Streaks.categories\for_db params.category
    params.late_submit_type = Streaks.late_submit_types\for_db params.late_submit_type
    params.membership_type = Streaks.membership_types\for_db params.membership_type

    filter_update @streak, params

    if next params
      @streak\update params

    -- lazy
    @streak\get_user!\recount "hidden_streaks_count"

