import Model from require "lapis.db.model"

import insert_on_conflict_ignore from require "helpers.model"

import types from require "tableshape"

validate_value = types.one_of {
  types.string / (s) ->
    wb = require "widgets.base"
    wb.truncate nil, s, 200
  types.any / nil
}

class RegisterReferrers extends Model
  @relations: {
    {"user", belongs_to: "Users"}
  }

  @create: insert_on_conflict_ignore

  @create_from_req: (user, req) =>
    return unless user

    import REFERRER_COOKIE, LANDING_COOKIE from require "helpers.referrers"

    fields = {
      referrer: validate_value\transform req.cookies[REFERRER_COOKIE]
      landing: validate_value\transform req.cookies[LANDING_COOKIE]
      accept_lang: validate_value\transform ngx.var.http_accept_language
      user_agent: validate_value\transform ngx.var.http_user_agent
    }

    if next fields
      fields.user_id = user.id
      @create fields

