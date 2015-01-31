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
    @admin

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

  find_active_streaks: (opts={}) =>
    import Streaks from require "models"
    Streaks\select "
      where id in (select streak_id from streak_users where user_id = ?) and
      start_date <= now() at time zone 'utc' + (hour_offset || ' hours')::interval and
      end_date > now() at time zone 'utc' + (hour_offset || ' hours')::interval
      #{opts.status and "and publish_status = ?" or ""}
      order by id desc
    ", @id, opts.status

  find_submittable_streaks: (unit_date=date true) =>
    import StreakUsers from require "models"
    active_streaks = @find_active_streaks!
    StreakUsers\include_in active_streaks, "streak_id", {
      flip: true
      where: { user_id: @id }
    }

    return for streak in *active_streaks
      streak.streak_user.streak = streak
      if streak.streak_user\submission_for_date unit_date
        continue
      streak

  find_all_streaks: =>
    import Streaks from require "models"
    Streaks\select [[
      where id in (select streak_id from streak_users where user_id = ?) order by id desc
    ]], @id

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

  recount: =>
    @update {
      likes_count: db.raw db.interpolate_query [[
        (select count(*) from submission_likes where user_id = ?)
      ]], @id

      submissions_count: db.raw db.interpolate_query [[
        (select count(*) from submissions where user_id = ?)
      ]], @id

      comments_count: db.raw db.interpolate_query [[
        (select count(*) from submission_comments where user_id = ?)
      ]], @id

      streaks_count: db.raw db.interpolate_query [[
        (select count(*) from streaks where user_id = ?)
      ]], @id

      followers_count: db.raw db.interpolate_query [[
        (select count(*) from followings where dest_user_id = ?)
      ]], @id

      following_count: db.raw db.interpolate_query [[
        (select count(*) from followings where source_user_id = ?)
      ]], @id
    }

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

