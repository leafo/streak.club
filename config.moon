import config from require "lapis.config"

config {"development", "test"}, ->
  session_name "streakclub"
  app_name "streak.club"
  host "localhost"
  user_content_path "user_content"

  postgres {
    backend: "pgmoon"
    database: "streakclub"
  }

config "test", ->
  postgres {
    backend: "pgmoon"
    database: "streakclub_test"
  }
