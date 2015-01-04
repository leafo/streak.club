import config from require "lapis.config"

config {"development", "test"}, ->
  session_name "streakclub"
  app_name "streak.club"
  host "localhost"
  user_content_path "user_content"

  -- my Redactor license doesn't let me bundle it with opensource so you'll
  -- have to disable it here if you don't have it. Otherwise place in
  -- static/lib/redactor/
  enable_redactor true

  postgres {
    backend: "pgmoon"
    database: "streakclub"
  }

config "test", ->
  postgres {
    backend: "pgmoon"
    database: "streakclub_test"
  }
