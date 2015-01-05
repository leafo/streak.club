db = require "lapis.db"
import Model, enum from require "lapis.db.model"
import safe_insert from require "helpers.model"

date = require "date"

class Streaks extends Model
  @day_format_str: "%Y-%m-%d"
  @timestamp_format_str: "%Y-%m-%d %H:%M:%S"
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

  submit: (submission, submit_time=db.format_date!) =>
    import StreakSubmissions from require "models"
    res = safe_insert StreakSubmissions, {
      submission_id: submission.id
      streak_id: @id
      :submit_time
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

  allowed_to_submit: (user, check_time=true) =>
    return false unless user
    su = @has_user user
    return false unless su

    if check_time
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

  interval_noun: =>
    switch @rate
      when @@rates.daily
        "daily"
      when @@rates.weekly
        "weekly"

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

  date_in_streak: (d) =>
    return false if d < @start_datetime!
    return false if @end_datetime! < d
    true

  unit_submission_counts: =>
    import StreakSubmissions from require "models"

    interval = "#{@hour_offset} hours"

    fields = db.interpolate_query [[
      count(*),
      (submit_time - ?::interval)::date submit_day
    ]], interval

    res = StreakSubmissions\select [[
      where streak_id = ?
      group by submit_day
    ]], @id, :fields

    {s.submit_day, s.count for s in *res}

  find_submissions_for_unit: (unit_date, opts) =>
    import StreakSubmissions, Submissions, Users, Uploads from require "models"

    unit_start = @truncate_date unit_date
    unit_end = @increment_date_by_unit date unit_start

    unit_start_formatted = unit_start\fmt @@timestamp_format_str
    unit_end_formatted = unit_end\fmt @@timestamp_format_str

    interval = "#{@hour_offset} hours"

    StreakSubmissions\paginated [[
      where
        streak_id = ? and
        submit_time >= ?::timestamp and
        submit_time < ?::timestamp
      order by submit_time desc
    ]], @id, unit_start_formatted, unit_end_formatted, {
      per_page: 20
      prepare_results: (submits) ->
        Submissions\include_in submits, "submission_id"

        submits_by_submission_id = {s.submission_id, s for s in *submits}
        submissions = [s.submission for s in *submits]

        for s in *submissions
          s.streak_submission = submits_by_submission_id[s.id]

        if opts and opts.prepare_submissions
          opts.prepare_submissions submissions
        else
          submissions
    }

  find_users: =>
    import StreakUsers, Users from require "models"
    StreakUsers\paginated [[
      where streak_id = ?
      order by user_id asc
    ]], @id, {
      per_page: 200
      prepare_results: (streak_users) ->
        Users\include_in streak_users, "user_id"
        [su.user for su in *streak_users]
    }
