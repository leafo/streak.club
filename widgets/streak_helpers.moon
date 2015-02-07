StreakUnits = require "widgets.streak_units"

class StreakHelpers
  render_streak_row: (streak) =>
    div class: "streak_row", ->
      h3 ->
        a href: @url_for(streak), streak.title

      h4 streak.short_description
      p class: "streak_sub", ->
        text "#{streak\interval_noun!} from "
        nobr streak.start_date
        text " to "
        nobr streak.end_date

      if streak.completed_units
        p class: "streak_sub", ->
          if streak\after_end!
            longest = streak.streak_user\get_longest_streak!
            rate = streak.streak_user\completion_rate!
            rate = math.floor rate * 100

            text "Best streak: #{longest}, Completion: #{rate}%"
          else
            current = streak.streak_user\get_current_streak!
            longest = streak.streak_user\get_longest_streak!
            text "Streak: #{current}, Longest: #{longest}"

        widget StreakUnits streak: streak, completed_units: streak.completed_units

