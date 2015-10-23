import config from require "lapis.config"

config {"development", "test", "production"}, ->
  code_cache "off"
  daemon "off"
  notice_log "stderr"
  admin_email "leafot@gmail.com"

  pcall ->
    include require "secret.keys"

  session_name "streakclub"
  app_name "streak.club"
  host "localhost"
  user_content_path "user_content"

  storage_bucket "streakclub_dev"

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

config "production", ->
  track_exceptions true
  admin_email "leafot@gmail.com"
  code_cache "on"
  port 10005
  daemon "on"
  notice_log "logs/notice.log"
  logging false
  num_workers 3

  storage_bucket "streakclub"

  enable_https true

  systemd {
    user: true
  }

