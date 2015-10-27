import use_test_env from require "lapis.spec"
import truncate_tables from require "lapis.spec.db"

import Streaks, Users, StreakUsers, StreakSubmissions,
  StreakUserNotificationSettings from require "models"

factory = require "spec.factory"

describe "models.streak_users", ->
  use_test_env!

  before_each ->
    truncate_tables Users, Streaks, StreakUsers

  it "gets notification settings", ->
    su = factory.StreakUsers!
    n = su\get_notification_settings!
    assert n
