StreakUnits = require "widgets.streak_units"

class StreakHelpers
  render_streak_row: (streak, opts={}) =>
    {:highlight_date, :show_user_streak, :user_id} = opts
    show_user_streak = true if show_user_streak == nil

    div class: "streak_row", ->
      h3 ->
        a href: @url_for(streak), streak.title

      h4 streak.short_description
      p class: "streak_sub", ->
        if streak.streak_user and not streak\after_end!
          su = streak.streak_user
          noun = streak\interval_noun false
          units = su\current_unit_number!
          units -= 1

          if units != 1
            noun ..= "s"

          if units == 0
            text "joined #{streak\unit_noun!}"
          else
            text "joined #{@number_format units} #{noun} ago"
        else
          text "#{streak\interval_noun!} from "
          nobr streak.start_date
          if streak\has_end!
            text " to "
            nobr streak.end_date

      if opts.hide_units_if_not_submitted
        return unless streak.completed_units and next streak.completed_units

      if streak.completed_units
        if show_user_streak
          if streak\after_end!
            longest = streak.streak_user\get_longest_streak!
            rate = streak.streak_user\completion_rate!

            p class: "streak_sub", ->
              text "Best streak: #{longest}"
              if rate
                rate = math.floor rate * 100
                text ", Completion: #{rate}%"
          else
            current = streak.streak_user\get_current_streak!
            longest = streak.streak_user\get_longest_streak!

            if current and longest
              p class: "streak_sub",
                "Streak: #{current}, Longest: #{longest}"

        widget StreakUnits {
          :streak, :highlight_date
          completed_units: streak.completed_units
          user_id: user_id
          start_date: streak.streak_user and streak.streak_user.created_at
        }

