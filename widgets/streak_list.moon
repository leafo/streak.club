import sanitize_html, is_empty_html from require "helpers.html"

class StreakList extends require "widgets.base"
  @needs: {"streaks"}

  base_widget: false

  inner_content: =>
    div class: "streak_list", ->
      i = 0
      for streak in *@streaks
        i += 1
        div class: "streak_box", ->
          div class: "box_content", ->
            h3 ->
              a href: @url_for(streak), streak.title

            div class: "streak_host", ->
              text " by "
              a href: @url_for(streak.user), streak.user\name_for_display!

            div class: "date_range", ->
              text "#{streak\interval_noun!} from "
              nobr streak.start_date
              text " to "
              nobr streak.end_date

            div class: "streak_stats", ->
              div class: "stat_box", ->
                div class: "stat_value", streak.users_count
                div class: "stat_label", "participants"

              div class: "stat_box", ->
                div class: "stat_value", streak.submissions_count
                div class: "stat_label", "submissions"


            if p = streak\progress!
              div class: "progress_row", ->
                div class: "progress_outer", ->
                  div class: "progress_inner", style: "width: #{p * 100}%"

              if p == 1
                div class: "status_message", "Streak ended"
            else
              div class: "pre_status_message", ->
                text "Hasn't started yet"

