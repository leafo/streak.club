
date = require "date"
db = require "lapis.db"
types = require "lapis.validate.types"
shapes = require "helpers.shapes"

import with_params from require "lapis.validate"

import assert_error from require "lapis.application"
import filter_update from require "helpers.model"

import Flow from require "lapis.flow"
import Streaks from require "models"

null_empty = types.empty / db.NULL

class EditStreakFlow extends Flow
  validate_params: with_params {
    {"timezone", shapes.timezone}
    {"streak", types.params_shape {
      {"title", types.limited_text 256}
      {"short_description", types.limited_text 1024 * 2}
      {"description", types.limited_text(1024 * 10) * -shapes.empty_html}

      {"start_date", shapes.datestamp}
      {"end_date", null_empty + shapes.datestamp}
      {"hour_offset", types.empty / 0 + (types.limited_text(10) * types.pattern("^-?%d+$") / tonumber)\describe("integer") * types.range(-12, 12)}

      {"publish_status", types.db_enum Streaks.publish_statuses}
      {"category", types.db_enum Streaks.categories}
      {"membership_type", types.db_enum Streaks.membership_types}
      {"rate", types.db_enum Streaks.rates}
      {"late_submit_type", types.db_enum Streaks.late_submit_types}
      {"community_type", types.db_enum Streaks.community_types}
      {"twitter_hash", null_empty + shapes.twitter_hash}
    }}
  }, (params) =>
    streak_params = params.streak
    timezone = params.timezone

    -- apply timezone offset to put hour_offset into UTC time
    timezone_offset = tonumber timezone.utc_offset\match "^(-?%d+)"
    streak_params.hour_offset = timezone_offset - streak_params.hour_offset

    start_date = date streak_params.start_date

    if streak_params.end_date != db.NULL
      end_date = date streak_params.end_date
      assert_error start_date < end_date, "start date must be before end date"

    if streak_params.rate == "monthly"
      assert_error start_date\getday! <= 28,
        "Monthly streaks must have a start date before the 29th day of the month"

    streak_params

  create_streak: =>
    params = @validate_params!
    params.user_id = @current_user.id

    assert_error not @current_user\is_suspended!, "Your account is blocked, contact an admin"

    streak = Streaks\create params

    @current_user\update {
      streaks_count: db.raw "streaks_count + 1"
      hidden_streaks_count: if streak\is_hidden! or streak\is_draft!
        db.raw "hidden_streaks_count + 1"
    }

    @current_user\refresh_spam_scan!
    streak

  edit_streak: =>
    assert @streak
    params = @validate_params!

    filter_update @streak, params

    if next params
      @streak\update params
      @streak\get_user!\refresh_spam_scan!

    -- lazy
    @streak\get_user!\recount "hidden_streaks_count"

