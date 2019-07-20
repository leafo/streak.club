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

  resolver "8.8.8.8"

  postgres {
    backend: "pgmoon"
    database: "streakclub"
  }

  community {
    view_counter_dict: "community_view_counters"
  }

config "test", ->
  port 80 -- to generate portless URLs
  code_cache "on"
  disable_email true

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

  host "streak.club"

  storage_bucket "streakclub"

  resolver "127.0.0.1 ipv6=off"

  enable_https true

  systemd {
    user: true
  }

