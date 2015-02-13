db = require "lapis.db"
import Model from require "lapis.db.model"

import safe_insert from require "helpers.model"

class SubmissionLikes extends Model
  @timestamp: true
  @primary_key: {"submission_id", "user_id"}

  @relations: {
    {"user", belongs_to: "Users"}
    {"submission", belongs_to: "Submissions"}
  }

  @create: (opts={}) =>
    assert opts.user_id, "missing user_id"
    assert opts.submission_id, "missing submission_id"

    res = safe_insert @, opts

    if res.affected_rows != 1
      return false

    with SubmissionLikes\load (unpack res)
      \increment!

  increment: (amount=1) =>
    amount = assert tonumber amount
    import Submissions, Users from require "models"

    Users\load(id: @user_id)\update {
      likes_count: db.raw "likes_count + #{amount}"
    }, timestamp: false

    Submissions\load(id: @submission_id)\update {
      likes_count: db.raw "likes_count + #{amount}"
    }, timestamp: false

  delete: =>
    if super!
      @increment -1
      true

