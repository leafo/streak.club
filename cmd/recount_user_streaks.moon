
import StreakUsers from require "models"

for user in *StreakUsers\select!
  user\update_streaks!

