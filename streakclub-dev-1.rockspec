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

  "lapis ~> 1.9",
  "lapis-community dev", -- currently not versioned...

  "lapis-exceptions ~> 2.1",
  "lapis-bayes ~> 1.1",
  "lapis-systemd ~> 1.0",
  "lapis-console ~> 1.2",
  "cloud_storage ~> 1.1",
  "mailgun ~> 1.2",
  "web_sanitize ~> 1.1",
  "magick ~> 1.6",
  "luajit-geoip ~> 2.1",
  "tableshape ~> 2.2",
}

build = {
  type = "none"
}
