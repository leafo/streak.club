db = require "lapis.db"
import Model from require "lapis.db.model"

bcrypt = require "bcrypt"
import slugify from require "lapis.util"

class Users extends Model
  @timestamp: true

  @constraints: {
    slug: (value) =>
      if @check_unique_constraint "slug", value
        return "Username already taken"

    username: (value) =>
      if @check_unique_constraint "username", value
        "Username already taken"

    email: (value) =>
      if @check_unique_constraint { [db.raw"lower(username)"]: value }
        "Username already taken"
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
    opts.slug = slugify opts.username

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

