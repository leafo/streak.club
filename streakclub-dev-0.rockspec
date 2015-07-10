
package = "streakclub"
version = "dev-1"

source = {
  url = "git://github.com/leafo/streak.club.git",
}

description = {
  summary = "Streak Club",
  homepage = "https://streak.club",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
}

dependencies = {
  "lpeg = 0.10.2-1",
  "moonscript",
  "bcrypt",
  "date",
  "https://raw.githubusercontent.com/leafo/lapis/master/lapis-dev-1.rockspec",
  "https://raw.githubusercontent.com/leafo/lapis-exceptions/master/lapis-exceptions-dev-1.rockspec",
  "https://raw.githubusercontent.com/leafo/cloud_storage/master/cloud_storage-dev-1.rockspec",
  "https://raw.githubusercontent.com/leafo/web_sanitize/master/web_sanitize-dev-1.rockspec",
  "https://raw.githubusercontent.com/leafo/magick/master/magick-dev-1.rockspec",
}

build = {
  type = "builtin",
  modules = { }
}

