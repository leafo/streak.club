import use_test_server from require "lapis.spec"
import request from require "lapis.spec.server"
import truncate_tables from require "lapis.spec.db"

import stub_email, assert_email_sent, assert_emails_sent from require "spec.helpers.email"
import Streaks, StreakUsers, StreakSubmissions, Submissions, Users from require "models"

factory = require "spec.factory"

describe "emails", ->
  use_test_server!
  last_email, req = stub_email!

  before_each ->
    truncate_tables Streaks, StreakUsers, StreakSubmissions, Submissions, Users

  it "sends password reset email", ->
    user = factory.Users!
    reset_url = "http://leafo.net"

    mailer = require "emails.password_reset"
    mailer\send req, user.email, { :reset_url, :user }

    recipient, subject, body, opts = unpack last_email!
    assert.same recipient, user.email


