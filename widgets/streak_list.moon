class StreakList extends require "widgets.base"
  @needs: {"streaks"}

  show_submit_button: false

  inner_content: =>
    i = 0
    for streak in *@streaks
      i += 1
      div class: "streak_box", ->
        if streak\is_hidden!
          div class: "streak_tag hidden_tag", "Hidden"

        if streak\is_draft!
          div class: "streak_tag draft_tag", "Draft"

        div class: "upper_content", ->
          h3 ->
            a href: @url_for(streak), streak.title

          if @show_short_description and streak.short_description
            p class: "short_description", streak.short_description

          unless @as_participant
            div class: "streak_host", ->
              text " by "
              a href: @url_for(streak.user), streak.user\name_for_display!

          div class: "date_range", ->
            if not streak\has_end! and streak\during!
              text "Submit #{streak\interval_noun!}"

              if streak\is_public_membership!
                text ", open membership"
            else
              text "#{streak\interval_noun!} from "
              nobr streak.start_date
              if streak\has_end!
                text " to "
                nobr streak.end_date

        div class: "lower_content", ->
          div class: "streak_stats", ->
            if @as_participant
              streak_user = streak\has_user @current_user
              div class: "stat_box", ->
                div class: "stat_value", @number_format streak_user.submissions_count
                div class: "stat_label", "submissions"

              if streak_user.current_streak == 0 and streak_user.submissions_count > 0
                div class: "stat_box", ->
                  div class: "stat_value", @number_format streak_user.longest_streak
                  div class: "stat_label", "longest streak"
              else
                div class: "stat_box", ->
                  div class: "stat_value", @number_format streak_user.current_streak
                  div class: "stat_label", "current streak"

              if streak\during! and streak\has_end!
                streak_user = streak\has_user @current_user
                div class: "stat_box", ->
                  div class: "stat_value", @number_format streak_user\current_unit_number!
                  div class: "stat_label", streak\interval_noun false
            else
              div class: "stat_box", ->
                div class: "stat_value", @number_format streak\approved_participants_count!
                div class: "stat_label", "participants"

              div class: "stat_box", ->
                div class: "stat_value", @number_format streak.submissions_count
                div class: "stat_label", "submissions"



          if streak\has_end!
            p = streak\progress!
            if p == 1
              div class: "status_message", ->
                text "Completed"
            elseif not p
              div class: "status_message", "Hasn't started yet"

          if @show_submit_button and not streak\after_end! and not streak\before_start!
            -- TODO: n + 1 query
            streak_user = streak\has_user @current_user
            current_submit = if streak_user
              streak_user\current_unit_submission!

            if current_submit
              div class: "status_message", "You already submitted"
            elseif streak\allowed_to_submit @current_user
              a {
                href: @url_for("new_submission") .. "?streak_id=#{streak.id}"
                class: "button submit_btn outline"
                "Submit #{streak\unit_noun!}"
              }

            if streak\has_end!
              p = streak\progress!
              if p and p > 0 and p < 1
                div class: "progress_row", ->
                  div class: "progress_outer", ->
                    div class: "progress_inner", style: "width: #{p * 100}%"

