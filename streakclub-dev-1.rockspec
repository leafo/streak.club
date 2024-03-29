package = "streakclub"
version = "dev-1"

source = {
  url = "git://github.com/leafo/streak.club.git"
}

description = {
  summary = "A website for streaking",
  homepage = "https://streak.club",
  license = "GPLv2"
}

dependencies = {
  "lua ~> 5.1",
  "moonscript",
  "bcrypt",

  "lapis >= 1.16",
  "lapis-community == 1.44.3",
  "lapis-eswidget >= 1.1.0",

  "lapis-exceptions >= 2.3",
  "lapis-bayes >= 1.2",
  "lapis-systemd >= 1.0",
  "lapis-console >= 1.2",
  "cloud_storage >= 1.3",
  "mailgun >= 1.2",
  "web_sanitize >= 1.4",
  "magick >= 1.6",
  "luajit-geoip >= 2.1",
  "tableshape >= 2.5",
}

build = {
  type = "none"
}
