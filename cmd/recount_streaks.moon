import Streaks from require "models"
for streak in *Streaks\select!
  streak\recount!
