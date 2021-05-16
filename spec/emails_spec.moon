import use_test_server from require "lapis.spec"
import request from require "lapis.spec.server"

import stub_email, assert_email_sent, assert_emails_sent from require "spec.helpers.email"

db = require "lapis.db"

date = require "date"

factory = require "spec.factory"

describe "emails", ->
  use_test_server!
  last_email, req = stub_email!

  import Streaks, StreakUsers, StreakSubmissions, Submissions, Users from require "spec.models"

  it "sends password reset email", ->
    user = factory.Users!
    reset_url = "http://leafo.net"

    mailer = require "emails.password_reset"
    mailer\send req, user.email, { :reset_url, :user }

    recipient, subject, body, opts = unpack last_email!
    assert.same recipient, user.email

  it "sends generic streak email", ->
    -- TODO: this should be moved into a flow so we don't have to duplicate
    -- logic from admin action

    users = {
      factory.Users!
    }

    template = require "emails.generic_email"
    t = template {
      email_body: "<p>Here is your custom email</p>"
      email_subject: "A test email"
      show_tag_unsubscribe: true
    }

    t\include_helper @

    import send_email from require "helpers.email"
    send_email [u.email for u in *users], t\subject!, t\render_to_string!, {
      html: true
      sender: "Streak Club <postmaster@streak.club>"
      tags: { "test_email" }
      vars: { u.email, { name_for_display: u\name_for_display! } for u in *users }
      track_opens: true
      headers: {
        "Reply-To": require("lapis.config").get!.admin_email
      }
    }

    recipient, subject, body, opts = unpack last_email!
    assert.same recipient, {users[1].email}
    assert.same opts.vars, {
      [users[1].email]: { name_for_display: users[1]\name_for_display! }
    }

  describe "deadline email", ->
    it "sends first deadline email", ->
      s = factory.Streaks state: "first_unit"

      emailer = require "emails.deadline_email"
      emailer\send req, "leafot@gmail.com", {
        streak: factory.Streaks state: "first_unit"
      }

    it "sends some unit deadline email", ->
      emailer = require "emails.deadline_email"
      emailer\send req, "leafot@gmail.com", {
        streak: factory.Streaks state: "during"
      }

    it "attemps to send deadline email to empty streak", ->
      streak = factory.Streaks state: "first_unit"
      assert.same {nil, "no emails"}, {streak\send_deadline_email req}
      assert.nil last_email!

    it "sends deadline email to streak", ->
      streak = factory.Streaks state: "first_unit"
      su = factory.StreakUsers streak_id: streak.id

      streak\send_deadline_email req
      recipients, title, body, opts = unpack last_email!

      assert.same {su\get_user!.email}, recipients
      assert.same {"deadline_email"}, opts.tags
      assert.same {
        [su\get_user!.email]: {
          name_for_display: su\get_user!\name_for_display!
        }
      }, opts.vars

    it "doesn't send deadline email if already sent", ->
      streak = factory.Streaks state: "first_unit", last_deadline_email_at: db.format_date!
      su = factory.StreakUsers streak_id: streak.id
      assert.same {nil, "already reminded for this unit"},
        {streak\send_deadline_email req}

    it "doesn't send deadline email if another thread sends it sent", ->
      streak = factory.Streaks state: "first_unit"
      db.update "streaks", {
        last_deadline_email_at: db.format_date!
      }, {
        id: streak.id
      }

      assert.same {nil, "failed to get lock on deadline email"},
        {streak\send_deadline_email req}

  describe "late submit email", ->
    it "sends late submit email", ->
      emailer = require "emails.late_submit_email"
      emailer\send req, "leafot@gmail.com", {
        streak: factory.Streaks state: "during", late_submit_type: "public"
      }

    it "sends late submit email from streak #ddd", ->
      streak = factory.Streaks state: "during", late_submit_type: "public"
      su = factory.StreakUsers streak_id: streak.id

      -- give them a submission in the current unit, should have no effec:
      future = streak\current_unit!\addminutes(60)
      factory.StreakSubmissions {
        streak_id: streak.id
        user_id: su.user_id
        submit_time: future\fmt(Streaks.timestamp_format_str) .. " UTC"
      }

      assert.same 1, streak\send_late_submit_email req

      recipients, title, body, opts = unpack last_email!

      assert.same {su\get_user!.email}, recipients
      assert.same {"late_submit_email"}, opts.tags
      assert.same {
        [su\get_user!.email]: {
          name_for_display: su\get_user!\name_for_display!
        }
      }, opts.vars

      su\refresh!
      notification_settings = su\get_notification_settings!
      notification_settings\refresh!
      assert.truthy notification_settings.late_submit_reminded_at

    it "doesn't send email to users who have submitted", ->
      streak = factory.Streaks state: "during", late_submit_type: "public"
      streak\refresh!

      su = factory.StreakUsers streak_id: streak.id

      ago = streak\current_unit!\addminutes(-60)

      factory.StreakSubmissions {
        streak_id: streak.id
        user_id: su.user_id
        submit_time: ago\fmt(Streaks.timestamp_format_str) .. " UTC"
      }

      assert.same nil, (streak\send_late_submit_email req)

    it "doesn't send late email if another thread sends it sent", ->
      streak = factory.Streaks state: "first_unit", late_submit_type: "public"
      db.update Streaks\table_name!, {
        last_late_submit_email_at: db.format_date!
      }, {
        id: streak.id
      }

      assert.same {nil, "failed to get lock on late submit email"},
        {streak\send_late_submit_email req}

