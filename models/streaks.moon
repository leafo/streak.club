db = require "lapis.db"
import Model, enum from require "lapis.db.model"
import safe_insert from require "helpers.model"

date = require "date"

import slugify from require "lapis.util"

prepare_submits = (opts) ->
  import Submissions from require "models"
  (submits) ->
    Submissions\include_in submits, "submission_id"

    submits_by_submission_id = {s.submission_id, s for s in *submits}
    submissions = [s.submission for s in *submits when s.submission]

    for s in *submissions
      s.streak_submission = submits_by_submission_id[s.id]

    if opts and opts.prepare_submissions
      opts.prepare_submissions submissions
    else
      submissions

-- How to use hour_offset
-- convert UTC time to local, add hour_offset to time
-- convert local time to UTC: subtract hour_offset from time
class Streaks extends Model
  @day_format_str: "%Y-%m-%d"
  @timestamp_format_str: "%Y-%m-%d %H:%M:%S"
  @timestamp: true

  @relations: {
    {"featured_streak", has_one: "FeaturedStreaks"}
    {"user", belongs_to: "Users"}
  }

  @rates: enum {
    daily: 1
    weekly: 2
  }

  @categories: enum {
    visual_art: 1
    music: 2
    video: 3
    writing: 4
    interactive: 5
    other: 6
  }

  @publish_statuses: enum {
    draft: 1
    published: 2
    hidden: 3
  }

  @late_submit_types: enum {
    admins_only: 1
    public: 2
  }

  @membership_types: enum {
    public: 1
    members_only: 2
  }

  @create: (opts={}) =>
    assert opts.user_id, "missing user_id"
    opts.rate = @rates\for_db opts.rate
    opts.publish_status = @publish_statuses\for_db opts.publish_status or "draft"
    opts.rate = @rates\for_db opts.rate or "daily"
    opts.category = @categories\for_db opts.category or "other"
    opts.late_submit_type = @late_submit_types\for_db opts.late_submit_type or "admins_only"
    opts.membership_type = @membership_types\for_db opts.membership_type or "public"

    Model.create @, opts

  @group_by_state: (streaks) =>
    grouped = {}

    for s in *streaks
      key = if s\during!
        "active"
      elseif s\before_start!
        "upcoming"
      else
        "completed"

      grouped[key] or= {}
      table.insert grouped[key], s

    grouped

  has_user: (user) =>
    import StreakUsers from require "models"
    return nil unless user
    StreakUsers\find user_id: user.id, streak_id: @id

  join: (user) =>
    import StreakUsers from require "models"
    pending = not not (@is_members_only! and user.id != @user_id)
    res = safe_insert StreakUsers, streak_id: @id, user_id: user.id, :pending

    if res.affected_rows != 1
      return false

    @update { users_count: db.raw "users_count + 1" }, timestamp: false
    StreakUsers\load (unpack res)

  leave: (user) =>
    if su = @has_user user
      if su\delete!
        @update { users_count: db.raw "users_count - 1" }, timestamp: false
        return true

    false

  submit: (submission, submit_time) =>
    late_submit = false

    if submit_time
      late_submit = true
    else
      submit_time = db.format_date!

    import StreakSubmissions from require "models"
    res = safe_insert StreakSubmissions, {
      submission_id: submission.id
      streak_id: @id
      :late_submit
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
    if @publish_status == @@publish_statuses.draft
      return @allowed_to_edit user

    true

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    user.id == @user_id

  allowed_to_submit: (user, check_time=true) =>
    return false unless user
    su = @has_user user
    return false unless su

    return false if @is_members_only! and su.pending

    if check_time
      now = date true
      start_date = @start_datetime!
      end_date = @end_datetime!

      return false if now < start_date
      return false if end_date < now

    true

  slug: =>
    slug = slugify @title
    slug = "-" if slug == ""
    slug

  url_params: =>
    "view_streak", id: @id, slug: @slug!

  unit_noun: =>
    switch @rate
      when @@rates.daily
        "today"
      when @@rates.weekly
        "this week"

  interval_noun: (ly=true) =>
    switch @rate
      when @@rates.daily
        if ly
          "daily"
        else
          "day"
      when @@rates.weekly
        if ly
          "weekly"
        else
          "week"

  increment_date_by_unit: (date, mul=1) =>
    switch @rate
      when @@rates.daily
        date\adddays 1 * mul
      when @@rates.weekly
        date\adddays 7 * mul
      else
        error "don't know how to increment rate"

  -- DON'T EDIT DATE
  format_date_unit: (d) =>
    switch @rate
      when @@rates.daily
        d\fmt "%m/%d/%Y"
      when @@rates.weekly
        tail = date(d)\adddays 6
        "#{d\fmt "%b %d"} to #{tail\fmt "%d"}"
      else
        error "don't know how to format date for rate"

  -- move UTC date to closest unit start in UTC
  truncate_date: (d) =>
    start = @start_datetime!

    switch @rate
      when @@rates.daily
        days = math.floor date.diff(d, start)\spandays!
        date(start)\adddays days
      when @@rates.weekly
        days = math.floor date.diff(d, start)\spandays!
        weeks = math.floor(days / 7)
        date(start)\adddays weeks * 7
      else
        error "don't know how to truncate date for rate"

  -- start date of current unit in UTC
  current_unit: =>
    return nil if @before_start! or @after_end!
    @truncate_date date true

  -- UTC date to unit number
  unit_number_for_date: (d) =>
    switch @rate
      when @@rates.daily
        math.floor(date.diff(d, @start_datetime!)\spandays!) + 1
      else
        days = math.floor date.diff(d, @start_datetime!)\spandays!
        weeks = math.floor(days / 7)
        weeks + 1

  -- get the starting time in UTC
  start_datetime: =>
    date(@start_date)\addhours -@hour_offset

  -- get the ending time in UTC
  end_datetime: =>
    date(@end_date)\addhours -@hour_offset

  before_start: =>
    date(true) < @start_datetime!

  after_end: =>
    @end_datetime! < date(true)

  during: =>
    not @before_start! and not @after_end!

  progress: =>
    return if @before_start!
    start = @start_datetime!
    now = date true
    math.min 1,
      date.diff(now, start)\spandays! / date.diff(@end_datetime!, start)\spandays!

  -- checks if UTC date is contained in streak
  date_in_streak: (d) =>
    return false if d < @start_datetime!
    return false if @end_datetime! < d
    true

  _streak_submit_unit_group_field: =>
    switch @rate
      when @@rates.daily
        interval = "#{@hour_offset} hours"
        db.interpolate_query [[
          (submit_time + ?::interval)::date submit_day
        ]], "#{@hour_offset} hours"
      when @@rates.weekly
        one_week = 60*60*24*7
        start = @start_datetime!
        unix_start = date.diff(start, date.epoch!)\spanseconds!

        db.interpolate_query [[
          (
            to_timestamp(
              (extract(epoch from submit_time)::integer - ?) / ? * ? + ?
            ) at time zone 'UTC' + ?::interval
          )::date submit_day
        ]], unix_start, one_week, one_week, unix_start, "#{@hour_offset} hours"
      else
        error "don't know how to "

  unit_submission_counts: =>
    import StreakSubmissions from require "models"

    fields = "count(*), " .. @_streak_submit_unit_group_field!
    res = StreakSubmissions\select [[
      where streak_id = ?
      group by submit_day
    ]], @id, :fields

    {s.submit_day, s.count for s in *res}

  find_submissions: (opts) =>
    import StreakSubmissions, Submissions, Users, Uploads from require "models"
    StreakSubmissions\paginated [[
      where streak_id = ?
      order by submit_time desc
    ]], @id, {
      per_page: opts.per_page or 20
      prepare_results: prepare_submits opts
    }

  -- unit date in UTC
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
        submit_time >= ? and
        submit_time < ?
      order by submit_time desc
    ]], @id, unit_start_formatted, unit_end_formatted, {
      per_page: 20
      prepare_results: prepare_submits opts
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

  is_draft: =>
    @publish_status == @@publish_statuses.draft

  is_hidden: =>
    @publish_status == @@publish_statuses.hidden

  is_members_only: =>
    @membership_type == @@membership_types.members_only

  -- each unit in utc
  each_unit: =>
    current = date @start_datetime!
    stop = date @end_datetime!
    coroutine.wrap ->
      while true
        coroutine.yield current
        @increment_date_by_unit current
        break if stop <= current

  -- each unit in local time stamp
  each_unit_local: =>
    coroutine.wrap ->
      for unit in @each_unit!
        coroutine.yield date(unit)\addhours(@hour_offset)\fmt Streaks.day_format_str

  recount: =>
    @update {
      users_count: db.raw db.interpolate_query [[
        (select count(*) from streak_users where streak_id = ?)
      ]], @id

      pending_users_count: db.raw db.interpolate_query [[
        (select count(*) from streak_users where streak_id = ? and pending)
      ]], @id

      submissions_count: db.raw db.interpolate_query [[
        (select count(*) from streak_submissions where streak_id = ?)
      ]], @id
    }

  find_participants: (opts={}) =>
    import StreakUsers, Users from require "models"
    opts.prepare_results or= (s_users) ->
      Users\include_in s_users, "user_id"
      s_users

    StreakUsers\paginated "where streak_id = ? order by created_at desc", @id, opts

  find_longest_active_streakers: =>
    import StreakUsers, Users from require "models"

    ago = @increment_date_by_unit @truncate_date(date true), -1
    StreakUsers\paginated [[
      where streak_id = ? and last_submitted_at > ? and submissions_count > 0
      order by current_streak desc
    ]], @id, ago\fmt(@@timestamp_format_str), prepare_results: (sus) ->
      Users\include_in sus, "user_id"
      sus

  find_longest_streakers: =>
    import StreakUsers, Users from require "models"
    StreakUsers\paginated [[
      where streak_id = ? and submissions_count > 0
      order by longest_streak desc
    ]], @id, {
      prepare_results: (sus) ->
        Users\include_in sus, "user_id"
        sus
    }

  find_top_submissions: (opts={}) =>
    import StreakSubmissions, Submissions, Users, Uploads from require "models"

    -- todo: index
    StreakSubmissions\paginated [[
      inner join submissions on submission_id = submissions.id
      where streak_id = ?
      order by likes_count desc
    ]], @id, {
      fields: "streak_submissions.*"
      per_page: opts.per_page or 20
      prepare_results: prepare_submits opts
    }


  find_streak_user: (user) =>
    return unless user
    import StreakUsers from require "models"
    StreakUsers\find {
      streak_id: @id
      user_id: user.id
    }

  can_late_submit: (user) =>
    return false unless user
    @late_submit_type == @@late_submit_types.public

  is_hidden_from: (user) =>
    return false unless @is_hidden!
    return true unless user

    return false if user\is_admin!
    return false if user.id == @user_id
    true

  approved_participants_count: =>
    if @is_members_only!
      @users_count - @pending_users_count
    else
      @users_count

  @_time_clause: (state) =>
    switch state
      when "active"
        [[
          start_date <= now() at time zone 'utc' + (hour_offset || ' hours')::interval and
          end_date > now() at time zone 'utc' + (hour_offset || ' hours')::interval
        ]]
      when "upcoming"
        [[
          start_date > now() at time zone 'utc' + (hour_offset || ' hours')::interval
        ]]
      when "completed"
        [[
          end_date < now() at time zone 'utc' + (hour_offset || ' hours')::interval
        ]]
      else
        error "unknown state: #{state}"

