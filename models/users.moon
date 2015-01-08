db = require "lapis.db"
import Model from require "lapis.db.model"

bcrypt = require "bcrypt"
import slugify from require "lapis.util"

date = require "date"

strip_non_ascii = do
  filter_chars = (c, ...) ->
    return unless c
    if c >= 32 and c <= 126
      c, filter_chars ...
    else
      filter_chars ...

  (str) ->
    string.char filter_chars str\byte 1, -1

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

  @login: (username, password) =>
    username = username\lower!

    user = Users\find { [db.raw("lower(username)")]: username }
    if user and user\check_password password
      user
    else
      nil, "Incorrect username or password"

  @create: (opts={}) =>
    assert opts.password, "missing password for user"

    opts.encrypted_password = bcrypt.digest opts.password, bcrypt.salt 5
    opts.password = nil
    stripped = strip_non_ascii(opts.username)
    return nil, "username must be ASCII only" unless stripped == opts.username

    opts.slug = slugify opts.username
    assert opts.slugify != "", "slug is empty"

    Model.create @, opts

  @read_session: (r) =>
    if user_session = r.session.user
      if user_session.id
        user = @find user_session.id
        if user and user\salt! == user_session.key
          user

  write_session: (r) =>
    r.session.user = {
      id: @id
      key: @salt!
    }

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

  is_admin: =>
    false

  find_submissions: (extra_opts) =>
    import Submissions from require "models"

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

    Submissions\paginated [[
      where user_id = ? order by id desc
    ]], @id, opts

  get_active_streaks: =>
    unless @active_streaks
      import Streaks from require "models"
      @active_streaks = Streaks\select [[
        where id in (select streak_id from streak_users where user_id = ?) and
        start_date + (hour_offset || ' hours')::interval <= now() at time zone 'utc' and
        end_date + (hour_offset || ' hours')::interval > now() at time zone 'utc' and
        publish_status = ?
        order by id desc
      ]], @id, Streaks.publish_statuses.published

    @active_streaks

  get_all_streaks: =>
    unless @all_streaks
      import Streaks from require "models"
      @all_streaks = Streaks\select [[
        where id in (select streak_id from streak_users where user_id = ?) order by id desc
      ]], @id

    @all_streaks

  -- streaks user has control of
  get_created_streaks: =>
    unless @created_streaks
      import Streaks from require "models"
      @created_streaks = Streaks\select [[
        where user_id = ?
        order by id desc
      ]], @id

    @created_streaks

  gravatar: (size) =>
    url = "https://www.gravatar.com/avatar/#{ngx.md5 @email}?d=identicon"
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

