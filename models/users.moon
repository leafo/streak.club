db = require "lapis.db"
import Model from require "lapis.db.model"

bcrypt = require "bcrypt"
import slugify from require "lapis.util"

date = require "date"

log_rounds = 5

strip_non_ascii = do
  filter_chars = (c, ...) ->
    return unless c
    if c >= 32 and c <= 126
      c, filter_chars ...
    else
      filter_chars ...

  (str) ->
    string.char filter_chars str\byte 1, -1


-- Generated schema dump: (do not edit)
--
-- CREATE TABLE users (
--   id integer NOT NULL,
--   username character varying(255) NOT NULL,
--   encrypted_password character varying(255) NOT NULL,
--   email character varying(255) NOT NULL,
--   slug character varying(255) NOT NULL,
--   last_active timestamp without time zone,
--   display_name character varying(255),
--   avatar_url character varying(255),
--   created_at timestamp without time zone NOT NULL,
--   updated_at timestamp without time zone NOT NULL,
--   submissions_count integer DEFAULT 0 NOT NULL,
--   following_count integer DEFAULT 0 NOT NULL,
--   followers_count integer DEFAULT 0 NOT NULL,
--   admin boolean DEFAULT false NOT NULL,
--   streaks_count integer DEFAULT 0 NOT NULL,
--   comments_count integer DEFAULT 0 NOT NULL,
--   likes_count integer DEFAULT 0 NOT NULL,
--   hidden_submissions_count integer DEFAULT 0 NOT NULL,
--   hidden_streaks_count integer DEFAULT 0 NOT NULL,
--   last_seen_feed_at timestamp without time zone,
--   last_timezone character varying(255)
-- );
-- ALTER TABLE ONLY users
--   ADD CONSTRAINT users_pkey PRIMARY KEY (id);
-- CREATE UNIQUE INDEX users_lower_email_idx ON users USING btree (lower((email)::text));
-- CREATE UNIQUE INDEX users_lower_username_idx ON users USING btree (lower((username)::text));
-- CREATE UNIQUE INDEX users_slug_idx ON users USING btree (slug);
-- CREATE INDEX users_username_idx ON users USING gin (username public.gin_trgm_ops);
--
class Users extends Model
  @timestamp: true

  @constraints: {
    slug: (value) =>
      if @check_unique_constraint "slug", value
        return "Username already taken"

    username: (value) =>
      if @check_unique_constraint { [db.raw"lower(username)"]: value }
        "Username already taken"

    email: (value) =>
      if @check_unique_constraint "email", value
        "Email already taken"
  }

  @relations: {
    {"streak_users", has_many: "StreakUsers"}
    {"user_profile", has_one: "UserProfiles"}
    {"api_keys", has_many: "ApiKeys"}
  }

  @login: (username, password) =>
    username = username\lower!

    user = Users\find { [db.raw("lower(username)")]: username }
    if user and user\check_password password
      user
    else
      nil, "Incorrect username or password"

  @create: (opts={}) =>
    assert opts.password, "missing password for user"

    opts.encrypted_password = bcrypt.digest opts.password, log_rounds
    opts.password = nil
    stripped = strip_non_ascii(opts.username)
    return nil, "username must be ASCII only" unless stripped == opts.username

    opts.slug = slugify opts.username
    assert opts.slug != "", "slug is empty"

    Model.create @, opts

  @read_session: (r) =>
    if user_session = r.session.user
      if user_session.id
        user = @find user_session.id
        if user and user\salt! == user_session.key
          user

  set_password: (new_pass) =>
    @update encrypted_password: bcrypt.digest new_pass, log_rounds

  write_session: (r) =>
    r.session.user = {
      id: @id
      key: @salt!
    }

  allowed_to_edit: (user) =>
    return false unless user
    return true if user\is_admin!
    return true if user.id == @id
    false

  generate_password_reset: =>
    profile = @get_user_profile!
    import generate_key from require "helpers.keys"

    token = generate_key 30
    profile\update password_reset_token: token

    "#{@id}-#{token}"

  check_password: (pass) =>
    bcrypt.verify pass, @encrypted_password

  salt: =>
    @encrypted_password\sub 1, 29

  name_for_display: =>
    @display_name or @username

  update_last_active: =>
    span = if @last_active
      date.diff(date(true), date(@last_active))\spandays!

    if not span or span > 1
      @update { last_active: db.format_date! }, timestamp: false

  url_params: =>
    "user_profile", slug: @slug

  admin_url_params: (r, ...) =>
    "admin.user", { id: @id }, ...

  is_admin: =>
    @admin

  find_submissions: (extra_opts={}) =>
    import Submissions from require "models"

    show_hidden = false
    show_hidden = true if extra_opts.show_hidden
    extra_opts.show_hidden = nil

    tag = extra_opts.tag
    extra_opts.tag = nil

    opts = {
      per_page: 40
      prepare_results: (submissions) ->
        _, streaks = Submissions\preload_streaks submissions
        Users\include_in streaks, "user_id"
        submissions
    }

    if extra_opts
      for k, v in pairs extra_opts
        opts[k] = v

    clause = {
      user_id: @id
      hidden: false
    }

    if show_hidden
      clause.hidden = nil

    join = if tag
      -- TODO: this is inefficient
      opts.fields or= "submissions.*"
      clause = { db.raw("submissions.#{k}"), v for k,v in pairs clause }

      db.interpolate_query "inner join submission_tags
        on slug = ? and submission_id = submissions.id", tag

    Submissions\paginated "#{join or ""} where #{db.encode_clause clause} order by id desc", opts

  find_hosted_streaks: (opts={}) =>
    publish_status = opts.publish_status
    opts.publish_status = nil

    opts.per_page or= 25
    opts.prepare_results or= (streaks) ->
      Users\include_in streaks, "user_id"
      streaks

    import Streaks from require "models"
    Streaks\paginated "
      where user_id = ?
      #{publish_status and "and publish_status = ?" or ""}
      order by created_at desc
    ", @id, publish_status and Streaks.publish_statuses\for_db(publish_status), opts

  find_participating_streaks: (opts={}) =>
    import Streaks from require "models"

    publish_status = opts.publish_status
    opts.status = nil

    state = opts.state
    opts.state = nil

    opts.prepare_results or= (streaks) ->
      import Users from require "models"
      Users\include_in streaks, "user_id"
      streaks

    opts.per_page or= 25

    query = db.interpolate_query "
      where id in (select streak_id from streak_users where user_id = ?)
    ", @id

    if publish_status
      query ..= db.interpolate_query [[ and publish_status = ?]],
        Streaks.publish_statuses\for_db publish_status

    if state
      query ..= " and #{Streaks\_time_clause state}"

    Streaks\paginated "#{query} order by created_at desc", opts

  find_submittable_streaks: (unit_date=date true) =>
    import StreakUsers from require "models"
    active_streaks = @find_participating_streaks(state: "active", per_page: 100)\get_page!

    StreakUsers\include_in active_streaks, "streak_id", {
      flip: true
      where: { user_id: @id }
    }

    return for streak in *active_streaks
      streak.streak_user.streak = streak
      if streak.streak_user\submission_for_date unit_date
        continue
      streak

  gravatar: (size) =>
    url = "https://www.gravatar.com/avatar/#{ngx.md5 @email\lower!}?d=identicon"
    url = url .. "&s=#{size}" if size
    url

  suggested_submission_tags: =>
    import SubmissionTags from require "models"

    tags = SubmissionTags\select "
      where submission_id in (select id from submissions where user_id = ?)
    ", @id, fields: "distinct slug"

    [t.slug for t in *tags]

  followed_by: (user) =>
    return nil unless user
    import Followings from require "models"
    Followings\find dest_user_id: @id, source_user_id: user.id

  get_user_profile: =>
    unless @user_profile
      import UserProfiles from require "models"
      @user_profile = UserProfiles\find(@id) or UserProfiles\create user_id: @id

    @user_profile

  recount: (...) =>
    import Streaks from require "models"

    updates = {
      likes_count: db.raw db.interpolate_query [[
        (select count(*) from submission_likes where user_id = ?)
      ]], @id

      submissions_count: db.raw db.interpolate_query [[
        (select count(*) from submissions where user_id = ?)
      ]], @id

      hidden_submissions_count: db.raw db.interpolate_query [[
        (select count(*) from submissions where user_id = ? and hidden)
      ]], @id

      comments_count: db.raw db.interpolate_query [[
        (select count(*) from submission_comments where user_id = ?)
      ]], @id

      streaks_count: db.raw db.interpolate_query [[
        (select count(*) from streaks where user_id = ?)
      ]], @id

      hidden_streaks_count: db.raw db.interpolate_query [[
        (select count(*) from streaks where user_id = ? and publish_status != ?)
      ]], @id, Streaks.publish_statuses.published

      followers_count: db.raw db.interpolate_query [[
        (select count(*) from followings where dest_user_id = ?)
      ]], @id

      following_count: db.raw db.interpolate_query [[
        (select count(*) from followings where source_user_id = ?)
      ]], @id
    }

    if ...
      updates = {key, updates[key] for key in *{...}}

    @update updates, timestamp: false

  unseen_notifications: =>
    import Notifications from require "models"
    Notifications\select "where user_id = ? and not seen", @id

  find_followers: (opts={}) =>
    opts.prepare_results or= (follows) ->
      Users\include_in follows, "source_user_id"
      [f.source_user for f in *follows]

    import Followings from require "models"
    Followings\paginated [[
      where dest_user_id = ?
      order by created_at desc
    ]], @id, opts

  find_following: (opts={}) =>
    import Followings from require "models"

    opts.prepare_results or= (follows) ->
      Users\include_in follows, "dest_user_id"
      [f.dest_user for f in *follows]

    import Followings from require "models"
    Followings\paginated [[
      where source_user_id = ?
      order by created_at desc
    ]], @id, opts

  -- TODO: this query will not scale
  find_follower_submissions: (opts={}) =>
    import Submissions from require "models"

    opts.per_page or= 25
    opts.prepare_results or= (submissions)->
      _, streaks = Submissions\preload_streaks submissions
      Users\include_in streaks, "user_id"
      Users\include_in submissions, "user_id"
      submissions

    Submissions\paginated "
      where user_id in (
        select dest_user_id from followings where source_user_id = ?
      ) and not hidden
      order by created_at desc
    ", @id, opts

  -- TODO: this query will not scale
  unseen_feed_count: =>
    unless @last_seen_feed_at
      return @find_follower_submissions!\total_items!

    import Submissions from require "models"
    Submissions\count "
      user_id in (
        select dest_user_id from followings where source_user_id = ?
      ) and created_at > ? and not hidden
    ", @id, @last_seen_feed_at

  update_seen_feed: (date) =>
    return unless date
    return if date == @last_seen_feed_at
    @update {
      last_seen_feed_at: date
    }, timestamp: false

  -- without @
  twitter_handle: =>
    return unless @twitter
    @twitter\match("twitter.com/([^/]+)") or @twitter\match("^@(.+)") or @twitter

  submissions_count_for: (user) =>
    public_count = @submissions_count - @hidden_submissions_count
    return public_count unless user
    return @submissions_count if user\is_admin! or user.id == @id
    public_count

  streaks_count_for: (user) =>
    public_count = @streaks_count - @hidden_streaks_count
    return public_count unless user
    return @streaks_count if user\is_admin! or user.id == @id
    public_count

  has_tags: =>
    import SubmissionTags from require "models"
    not not unpack SubmissionTags\select "where user_id = ? limit 1", @id, fields: "1"

  tags_by_frequency: =>
    import SubmissionTags from require "models"
    SubmissionTags\select "
      where user_id = ?
      group by slug
      order by count desc
    ", @id, fields: "slug, count(*)", load: false
