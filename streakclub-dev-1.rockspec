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
  "lapis dev",
  "lapis-exceptions ~> 2.0",
  "lapis-bayes dev",
  "lapis-community dev",
  "lapis-systemd dev",
  "lapis-console dev",
  "cloud_storage dev",
  "mailgun dev",
  "web_sanitize dev",
  "magick dev",
  "tableshape dev",
}

build = {
  type = "none"
}
