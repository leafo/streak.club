

import Users from require "models"

for user in *Users\select!
  user\recount!
