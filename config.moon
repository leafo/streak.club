import config from require "lapis.config"

config {"development", "test"}, ->
  session_name "streakclub"
  app_name "streak.club"
  host "localhost"

  postgres {
    backend: "pgmoon"
    database: "streakclub"
  }

config "test", ->
  postgres {
    backend: "pgmoon"
    database: "streakclub_test"
  }
