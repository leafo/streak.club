db = require "lapis.db"
import Model, enum, preload from require "lapis.db.model"
import transition from require "helpers.model"

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
--   category integer,
--   twitter_hash text,
--   late_submit_type integer DEFAULT 1 NOT NULL,
--   membership_type integer DEFAULT 1 NOT NULL,
--   pending_users_count integer DEFAULT 0 NOT NULL,
--   last_deadline_email_at timestamp without time zone,
--   last_late_submit_email_at timestamp without time zone,
--   community_category_id integer,
--   community_type smallint DEFAULT 1 NOT NULL
-- );
-- ALTER TABLE ONLY streaks
--   ADD CONSTRAINT streaks_pkey PRIMARY KEY (id);
-- CREATE INDEX steaks_title_idx ON streaks USING gin (title public.gin_trgm_ops) WHERE ((NOT deleted) AND (publish_status = 2));
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

    {"streak_submissions",
      has_many: "StreakSubmissions",
      order: "submit_time asc"}

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
    monthly: 3
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

    super opts

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
    streak_user = StreakUsers\create {
      streak_id: @id
      user_id: user.id
      :pending
    }

    unless streak_user
      return false

    @update {
      users_count: db.raw "users_count + 1"
      pending_users_count: if pending
        db.raw "pending_users_count + 1"
    }, timestamp: false

    streak_user

  leave: (user) =>
    if su = @has_user user
      if su\delete!
        @update { users_count: db.raw "users_count - 1" }, timestamp: false
        @recount "pending_users_count"
        return true

    false

  submit: (submission, submit_time) =>
    submit_time or= db.format_date!
    late_submit = @current_unit_number! > @unit_number_for_date submit_time

    import StreakSubmissions from require "models"

    submission = StreakSubmissions\create {
      submission_id: submission.id
      streak_id: @id
      :late_submit
      :submit_time
      user_id: submission.user_id
    }

    if submission
      @update {
        submissions_count: db.raw "submissions_count + 1"
      }, timestamp: false

      if streak_user = submission\get_streak_user!
        streak_user\update {
          submissions_count: db.raw "submissions_count + 1"
        }, timestamp: false
        streak_user\update_streaks!

      submission

  -- for when we add additional owners
  is_host: (user) =>
    user and user.id == @user_id

  allowed_to_view: (user) =>
    if @publish_status == @@publish_statuses.draft
      return @allowed_to_edit user

    owner = @get_user!
    if owner\display_as_suspended user
      return false

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
      when @@rates.monthly
        "this month"

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
      when @@rates.monthly
        if ly
          "monthly"
        else
          "month"

  -- NOTE: this mutates the date object
  increment_date_by_unit: (date, mul=1) =>
    switch @rate
      when @@rates.daily
        date\adddays 1 * mul
      when @@rates.weekly
        date\adddays 7 * mul
      when @@rates.monthly
        -- TODO: this fails if the day is above 28
        date\addmonths 1 * mul
      else
        error "don't know how to increment rate"

  -- DON'T EDIT DATE
  format_date_unit: (d) =>
    switch @rate
      when @@rates.daily
        d\fmt "%Y-%m-%d"
      when @@rates.weekly
        tail = date(d)\adddays 6
        "#{d\fmt "%b %d"} to #{tail\fmt "%d"}"
      when @@rates.monthly
        d\fmt "%B %Y"
      else
        error "don't know how to format date for rate"

  -- return new date to closest unit start in UTC, returns in UTC time
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
      when @@rates.monthly
        -- convert to local
        local_d = date(d)\addhours @hour_offset
        ly, lm, ld = date(local_d)\getdate!

        cutoff_day = date(@start_date)\getday!

        if ld < cutoff_day
          lm -= 1

        date(ly, lm, cutoff_day)\addhours -@hour_offset
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
  -- NOTE: this does not verify that d is in valid date in streak
  unit_number_for_date: (d) =>
    @unit_span @start_datetime!, d

  -- how many units two dates cover (UTC dates)
  -- note that dates in the same unit will return 1
  unit_span: (start, stop) =>
    switch @rate
      when @@rates.daily
        math.floor(date.diff(stop, start)\spandays!) + 1
      when @@rates.weekly
        days = math.floor date.diff(stop, start)\spandays!
        weeks = math.floor(days / 7)
        weeks + 1
      when @@rates.monthly
        -- convert dates to local
        local_start = date(start)\addhours @hour_offset
        local_stop = date(stop)\addhours @hour_offset

        -- find units
        start_unit = local_start\getyear! * 12 + local_start\getmonth!
        end_unit = local_stop\getyear! * 12 + local_stop\getmonth!

        cutoff_day = date(@start_date)\getday!

        -- move back if they're before the right day
        if local_start\getday! < cutoff_day
          start_unit -= 1

        if local_stop\getday! < cutoff_day
          end_unit -= 1

        end_unit - start_unit + 1
      else
        error "don't know how to calculate unit span for rate"

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
        ]], interval
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

      when @@rates.monthly
        interval = "#{@hour_offset} hours"
        submit_local = db.interpolate_query "(submit_time + ?::interval)", interval
        cutoff_day = date(@start_date)\getday!

        -- TODO: this query isn't accurate will cause drifting in the months
        db.interpolate_query "
          make_date(
            extract(year from #{submit_local})::int,
            extract(month from #{submit_local})::int,
            1
          ) + (? - 1 || ' days')::interval - (case when extract(day from #{submit_local}) < ? then '1 day'::interval else '0 days'::interval end)
          as submit_day
        ", cutoff_day, cutoff_day
      else
        error "don't know how to group units for rate"

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

  is_public_membership: =>
    @membership_type == @@membership_types.public

  is_members_only: =>
    @membership_type == @@membership_types.members_only

  -- each year this streak takes place in, in local time. Used for rendering
  -- calendar page
  each_year: =>
    start_y = date(@start_datetime!)\getdate!

    current = date(start_y, 1, 1)
    stop = @end_datetime! or date(true)

    limit = 1000

    coroutine.wrap ->
      while current < stop
        limit -= 1
        if limit == 0
          error "each_year infinite loop detected"

        y = current\getdate!
        coroutine.yield y
        current\addyears 1

  -- each unit of the streak in UTC between (inclusive) the specified range
  each_unit_in_range: (range_left, range_right) =>
    range_right = date range_right
    current = @truncate_date range_left
    -- NOTE: truncate shifts before, so we increment once if the truncated
    -- date falls before our desired range

    if current < date(range_left)
      current = @increment_date_by_unit current

    -- don't show dates before the streak
    streak_start = @start_datetime!
    if current < streak_start
      current = streak_start

    stop = @end_datetime!

    limit = 1000

    coroutine.wrap ->
      while true
        break if current > range_right
        break if stop and current >= stop

        limit -= 1
        if limit == 0
          error "each_unit_in_range infinite loop detected"

        coroutine.yield current\copy!
        current = @increment_date_by_unit current

  -- each unit in utc
  each_unit: =>
    current = date @start_datetime!
    stop = @end_datetime!

    limit = 100000

    coroutine.wrap ->
      while true
        limit -= 1
        if limit == 0
          error "each_unit infinite loop detected"

        coroutine.yield current
        @increment_date_by_unit current
        break if stop and stop <= current

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
      preload s_users, "user"
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
    return false unless @is_hidden! or @is_draft!

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

  has_unread_community_topics: (user) =>
    category = @get_community_category!
    return unless category

    last_seen = category\find_last_seen_for_user user
    return unless last_seen
    category.user_category_last_seen = last_seen
    category\has_unread user

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

  utc_to_local: (d) =>
    date(d)\addhours @hour_offset

  local_to_utc: (d) =>
    date(d)\addhours -@hour_offset
