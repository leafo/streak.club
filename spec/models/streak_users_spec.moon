import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Streaks, Users, StreakUsers, StreakSubmissions,
  StreakUserNotificationSettings from require "models"

factory = require "spec.factory"

describe "models.streak_users", ->
  use_test_env!

  before_each ->
    truncate_tables Users, Streaks, StreakUsers


  describe "notification settings", ->
    it "gets notification settings", ->
      su = factory.StreakUsers!
      n = su\get_notification_settings!
      assert n

    it "checks if user can email", ->
      su = factory.StreakUsers!
      n = su\get_notification_settings!
      assert.true n\can_email!

