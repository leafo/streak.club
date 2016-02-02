import use_test_server from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import request, request_as from require "spec.helpers"

import Users, Streaks, Submissions from require "models"

factory = require "spec.factory"

describe "applications.admin", ->
  use_test_server!

  local current_user
  
  before_each ->
    truncate_tables Users, Streaks, Submissions
    current_user = factory.Users admin: true

  it "doesn't let non-admin load admin page", ->
    user = factory.Users!
    status = request_as user, "/admin/streaks"
    assert.same 404, status

  it "loads admin streaks", ->
    factory.Streaks!
    status = request_as current_user, "/admin/streaks"
    assert.same 200, status

  it "loads admin streak", ->
    streak = factory.Streaks!
    status = request_as current_user, "/admin/streak/#{streak.id}"
    assert.same 200, status

  it "loads send streak email", ->
    streak = factory.Streaks!
    status = request_as current_user, "/admin/email/#{streak.id}"
    assert.same 200, status

  it "loads admin submission", ->
    submission = factory.Submissions!
    status = request_as current_user, "/admin/submission/#{submission.id}"
    assert.same 200, status

  it "loads admin user", ->
    user = factory.Users!
    status = request_as current_user, "/admin/user/#{user.id}"
    assert.same 200, status

