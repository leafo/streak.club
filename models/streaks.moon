db = require "lapis.db"
import Model, enum from require "lapis.db.model"
import safe_insert from require "helpers.model"

date = require "date"

class Streaks extends Model
  @timestamp: true

  @rates: enum {
    daily: 1
    weekly: 1
  }

  @create: (opts={}) =>
    assert opts.user_id, "missing user_id"
    opts.rate = @rates\for_db opts.rate
    Model.create @, opts

  has_user: (user) =>
    import StreakUsers from require "models"
    return nil unless user
    StreakUsers\find user_id: user.id, streak_id: @id

  join: (user) =>
    import StreakUsers from require "models"
    res = safe_insert StreakUsers, streak_id: @id, user_id: user.id

    if res.affected_rows != 1
      return false

    @update { users_count: db.raw "users_count + 1" }, timestamp: false
    StreakUsers\load (unpack res)

  leave: (user) =>
    if su = @has_user user
      res = su\delete!
      if res.affected_rows > 0
        @update { users_count: db.raw "users_count - 1" }, timestamp: false
        return true

    false

  submit: (submission) =>
    import StreakSubmissions from require "models"
    res = safe_insert StreakSubmissions, {
      submission_id: submission.id
      streak_id: @id
      submit_time: db.format_date!
      user_id: submission.user_id
    }, {
      submission_id: submission.id
      streak_id: @id
    }

    if res.affected_rows != 1
      return false

    StreakSubmissions\load (unpack res)

  allowed_to_view: (user) =>
    true

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    user.id == @user_id

  allowed_to_submit: (user) =>
    return false unless user
    su = @has_user user
    return false unless su

    now = date true
    -- TODO: timezones
    start_date = date @start_date
    end_date = date @end_date

    return false if now < start_date
    return false if end_date < now

    true

  url_params: =>
    "view_streak", id: @id

  unit_noun: =>
    switch @rate
      when @@rates.daily
        "today"
      when @@rates.weekly
        "this week"

  increment_date_by_unit: (date) =>
    switch @rate
      when @@rates.daily
        date\adddays 1
      else
        error "not yet"

  format_date_unit: (date) =>
    switch @rate
      when @@rates.daily
        date\fmt "%m/%d/%Y"
      else
        error "not yet"

  -- move date to closest unit start date
  truncate_date: (d) =>
    switch @rate
      when @@rates.daily
        date(d\getdate!)\addhours @hour_offset
      else
        error "not yet"

  start_datetime: =>
    date(@start_date)\addhours @hour_offset

  end_datetime: =>
    date(@end_date)\addhours @hour_offset

  before_start: =>
    date(true) < @start_datetime!

  after_end: =>
    @end_datetime! < date(true)

  during: =>
    not @before_start! and not @after_end!

