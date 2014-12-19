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

  @create: (opts={}) =>
    assert opts.password, "missing password for user"

    opts.encrypted_password = bcrypt.digest opts.password, bcrypt.salt 5
    opts.password = nil
    opts.slug = slugify opts.username

    Model.create @, opts

  write_session: (r) =>
    r.session.user = {
      id: @id
      key: @salt!
    }

  salt: =>
    @encrypted_password\sub 1, 29
