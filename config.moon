import config from require "lapis.config"

config {"development", "test"}, ->
  app_name "streak.club"
  postgres {
    backend: "pgmoon"
    database: "streakclub"
  }

config "test", ->
  postgres {
    backend: "pgmoon"
    database: "streakclub_test"
  }
