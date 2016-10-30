db = require "lapis.db"
import Model, enum from require "lapis.db.model"
import safe_insert, transition from require "helpers.model"

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
-- Generated schema dump: (do not edit)
--
-- CREATE TABLE streaks (
--   id integer NOT NULL,
--   user_id integer NOT NULL,
--   title character varying(255) NOT NULL,
--   short_description text NOT NULL,
--   description text NOT NULL,
--   deleted boolean DEFAULT false NOT NULL,
--   start_date date NOT NULL,
--   end_date date,
--   rate integer DEFAULT 0 NOT NULL,
--   users_count integer DEFAULT 0 NOT NULL,
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   submissions_count integer DEFAULT 0 NOT NULL,
--   hour_offset integer DEFAULT 0 NOT NULL,
--   publish_status integer NOT NULL,
--   category integer DEFAULT 0 NOT NULL,
--   twitter_hash text,
--   late_submit_type integer DEFAULT 1 NOT NULL,
--   membership_type integer DEFAULT 1 NOT NULL,
--   pending_users_count integer DEFAULT 0 NOT NULL,
--   last_deadline_email_at timestamp without time zone,
--   last_late_submit_email_at timestamp without time zone
-- );
-- ALTER TABLE ONLY streaks
--   ADD CONSTRAINT streaks_pkey PRIMARY KEY (id);
-- CREATE INDEX steaks_title_idx ON streaks USING gin (title gin_trgm_ops) WHERE ((NOT deleted) AND (publish_status = 2));
-- CREATE INDEX streaks_publish_status_users_count_idx ON streaks USING btree (publish_status, users_count);
-- CREATE INDEX streaks_user_id_publish_status_created_at_idx ON streaks USING btree (user_id, publish_status, created_at);
--
class Streaks extends Model
  @day_format_str: "%Y-%m-%d"
  @timestamp_format_str: "%Y-%m-%d %H:%M:%S"
  @timestamp: true

  @relations: {
    {"featured_streak", has_one: "FeaturedStreaks"}
    {"user", belongs_to: "Users"}

    {"related_streaks",
      has_many: "RelatedStreaks"
      order: "position asc"
    }

    {"other_related_streaks",
      has_many: "RelatedStreaks"
      key: "other_streak_id"
      order: "position asc"
    }

    {"community_category", belongs_to: "Categories"}
  }

  @get_relation_model: (name) =>
    -- allow community relations to be referenced
    require("models")[name] or require("community.models")[name]

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

  @community_types: enum {
    none: 1
    discussion: 2
  }

  @create: (opts={}) =>
    assert opts.user_id, "missing user_id"
    opts.rate = @rates\for_db opts.rate
    opts.publish_status = @publish_statuses\for_db opts.publish_status or "draft"
    opts.rate = @rates\for_db opts.rate or "daily"
    opts.category = @categories\for_db opts.category or "other"
    opts.late_submit_type = @late_submit_types\for_db opts.late_submit_type or "admins_only"
    opts.membership_type = @membership_types\for_db opts.membership_type or "public"
    opts.community_type = @community_types\for_db opts.community_type or "discussion"

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

    @update {
      users_count: db.raw "users_count + 1"
      pending_users_count: if pending
        db.raw "pending_users_count + 1"
    }, timestamp: false

    StreakUsers\load (unpack res)

  leave: (user) =>
    if su = @has_user user
      if su\delete!
        @update { users_count: db.raw "users_count - 1" }, timestamp: false
        @recount "pending_users_count"
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

      return false if now < start_date

      if @end_date
        end_date = @end_datetime!
        return false if end_date < now

    true

  slug: =>
    slug = slugify @title
    slug = "-" if slug == ""
    slug

  url_params: =>
    "view_streak", id: @id, slug: @slug!

  admin_url_params: (r, ...) =>
    "admin.streak", { id: @id }, ...

  unit_url_params: (unit_number) =>
    -- url dates are in local time
    d = @increment_date_by_unit date(@start_date), unit_number - 1
    "view_streak_unit", id: @id, date: d\fmt @@day_format_str

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

  current_unit_number: =>
    @unit_number_for_date date true

  current_unit_end_date: =>
    @increment_date_by_unit @current_unit!

  -- UTC date to unit number
  unit_number_for_date: (d) =>
    @unit_span @start_datetime!, d

  -- how many units between two dates
  unit_span: (start, stop) =>
    switch @rate
      when @@rates.daily
        math.floor(date.diff(stop, start)\spandays!) + 1
      else
        days = math.floor date.diff(stop, start)\spandays!
        weeks = math.floor(days / 7)
        weeks + 1

  -- find all streak users who have not submitted to the unit
  find_unsubmitted_users: (d=date(true)) =>
    import StreakUsers, Users from require "models"

    unit_start = @truncate_date d
    unit_end = @increment_date_by_unit date unit_start

    unit_start_formatted = unit_start\fmt(Streaks.timestamp_format_str)
    unit_end_formatted = unit_end\fmt(Streaks.timestamp_format_str)

    sus = StreakUsers\select "
      where streak_id = ?
      and not exists(
        select 1 from streak_submissions
        where
          streak_submissions.streak_id = streak_users.streak_id and
          streak_submissions.user_id = streak_users.user_id and
          submit_time >= ? and
          submit_time < ?
      )
    ", @id, unit_start_formatted, unit_end_formatted

    Users\include_in sus, "user_id"
    for s in *sus
      s.streak = @

    sus

  -- get the starting time in UTC
  start_datetime: =>
    date(@start_date)\addhours -@hour_offset

  -- get the ending time in UTC
  end_datetime: =>
    return nil unless @end_date
    date(@end_date)\addhours -@hour_offset

  before_start: =>
    date(true) < @start_datetime!

  after_end: =>
    return false unless @end_date
    @end_datetime! < date(true)

  has_end: =>
    not not @end_date

  during: =>
    not @before_start! and not @after_end!

  progress: =>
    return unless @end_date
    return if @before_start!
    start = @start_datetime!
    now = date true
    math.min 1,
      date.diff(now, start)\spandays! / date.diff(@end_datetime!, start)\spandays!

  -- checks if UTC date is contained in streak
  date_in_streak: (d) =>
    return false if d < @start_datetime!
    if @end_date
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

    clause = if opts.where
      db.encode_clause opts.where

    StreakSubmissions\paginated "
      where
        streak_id = ? and
        submit_time >= ? and
        submit_time < ?
        #{clause and "and #{clause}" or ""}
      order by submit_time desc
    ", @id, unit_start_formatted, unit_end_formatted, {
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

  recount: (...) =>
    updates = {
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

    if ...
      updates = {key, updates[key] for key in *{...}}

    @update updates, timestamp: false

  find_participants: (opts={}) =>
    import StreakUsers, Users from require "models"
    opts.prepare_results or= (s_users) ->
      Users\include_in s_users, "user_id"
      s_users

    clause = db.encode_clause {
      streak_id: @id
      pending: opts.pending
    }

    StreakUsers\paginated "where #{clause} order by created_at desc", opts

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

  duration: =>
    return nil unless @end_date
    date.diff(@end_datetime!, @start_datetime!)\spandays!

  -- TODO: add a lock on this
  -- sends email to the previous unit
  send_late_submit_email: (req) =>
    unless @late_submit_type == @@late_submit_types.public
      return nil, "late submit disabled"

    ready = transition @, "last_late_submit_email_at",
      @last_late_submit_email_at or db.NULL,
      db.format_date!

    unless ready
      return nil, "failed to get lock on late submit email"

    prev_unit = @increment_date_by_unit @current_unit!, -1
    streak_users = @find_unsubmitted_users prev_unit

    import StreakUsers, StreakUserNotificationSettings from require "models"

    StreakUserNotificationSettings\preload_and_create streak_users

    emails, vars = StreakUsers\email_vars streak_users
    return nil, "no emails" unless next emails

    db.update StreakUserNotificationSettings\table_name!, {
      late_submit_reminded_at: db.format_date!
    }, {
      user_id: db.list [su.user_id for su in *streak_users]
      streak_id: @id
    }

    @send_email req, "emails.late_submit_email", emails, {
      streak: @
      show_tag_unsubscribe: true
    }, {
      :vars
      tags: { "late_submit_email" }
    }

    #emails

  send_deadline_email: (req) =>
    now = date true
    if now < @start_datetime!
      return nil, "before start"

    if @end_datetime! < now
      return nil, "after end"

    if @last_deadline_email_at
      last = date @last_deadline_email_at
      if @current_unit_number! == @unit_number_for_date last
        return nil, "already reminded for this unit"

    ready = transition @, "last_deadline_email_at",
      @last_deadline_email_at or db.NULL,
      db.format_date!

    unless ready
      return nil, "failed to get lock on deadline email"

    streak_users = @find_unsubmitted_users!
    import StreakUsers from require "models"
    emails, vars = StreakUsers\email_vars streak_users
    return nil, "no emails" unless next emails

    @send_email req, "emails.deadline_email", emails, {
      streak: @
      show_tag_unsubscribe: true
    }, {
      :vars
      tags: { "deadline_email" }
    }

    #emails

  send_email: (req, email, recipients, params, more_params={}) =>
    emailer = require email
    emailer\send req, recipients, params, {
      html: true
      sender: "Streak Club <postmaster@streak.club>"
      tags: more_params.tags
      vars: more_params.vars
      track_opens: true
      headers: {
        "Reply-To": require("lapis.config").get!.admin_email
      }
    }

  state_name: =>
    if @during!
      "active"
    elseif @before_start!
      "upcoming"
    else
      "completed"

  has_community: =>
    @community_type == @@community_types.discussion

  create_default_category: =>
    import Categories from require "community.models"

    unless @community_category_id
      category = Categories\create {
        user_id: @user_id
      }

      import transition from require "helpers.model"
      if transition @, "community_category_id", db.NULL, category.id
        return category

      category\delete!

    nil, "default category already exists"



  @_time_clause: (state) =>
    switch state
      when "active"
        [[
          start_date <= now() at time zone 'utc' + (hour_offset || ' hours')::interval and
          (end_date is null or end_date > now() at time zone 'utc' + (hour_offset || ' hours')::interval)
        ]]
      when "upcoming"
        [[
          start_date > now() at time zone 'utc' + (hour_offset || ' hours')::interval
        ]]
      when "completed"
        [[
          (end_date is not null and end_date < now() at time zone 'utc' + (hour_offset || ' hours')::interval)
        ]]
      else
        error "unknown state: #{state}"

