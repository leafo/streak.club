StatsHeader = require "widgets.stats_header"
import Streaks from require "models"
import BrowseStreaksFlow from require "flows.browse_streaks"

class StatsThisWeek extends require "widgets.base"
  @include "widgets.table_helpers"

  @needs: {
    "active_streaks"
    "popular_submissions"
    "top_users"
    "days"
  }

  base_widget: false

  inner_content: =>
    widget StatsHeader page_name: "this_week"

    div class: "responsive_column", ->
      @render_active_streaks!
      @render_popular_submissions!
      @render_top_users!
      @render_new_streaks!

  render_active_streaks: =>
    h3 "Streaks active in the past #{@days} days by submissions"

    element "table", class: "nice_table", ->
      thead ->
        tr ->
          td "Rank"
          td "Streak"
          td "Submissions"
          td "Category"
    
      for rank, active in ipairs @active_streaks
        streak = active.streak
        should_hide = streak\is_hidden! or streak\is_draft!

        unless @current_user and @current_user\is_admin!
          continue if should_hide

        tr ->
          td rank
          td ->
            a href: @url_for(active.streak), active.streak.title
            if should_hide
              text " "
              em class:"sub", "(Hidden)"

          td @number_format active.count

          td ->
            category_name = Streaks.categories[streak.category]
            slug = BrowseStreaksFlow.category_slugs[category_name]

            a {
              href: @url_for("streaks") .. "/#{slug}"
              BrowseStreaksFlow.category_names[category_name]
            }



  render_popular_submissions: =>
    h3 "Top submissions in the past #{@days} days by likes"

    element "table", class: "nice_table", ->
      thead ->
        tr ->
          td "Rank"
          td "Submission"
          td "Creator"
          td "Likes"

      for rank, sub in ipairs @popular_submissions
        should_hide = sub.hidden

        unless @current_user and @current_user\is_admin!
          continue if should_hide

        tr ->
          td rank
          td ->
            a href: @url_for(sub), ->
              if sub.title
                text sub.title
              else
                em "untitled"

            if should_hide
              text " "
              em class:"sub", "(Hidden)"

          td ->
            a href: @url_for(sub.user), sub.user\name_for_display!

          td @number_format sub.likes_count

  render_top_users: =>
    h3 "Top submitters in the past #{@days} days"

    element "table", class: "nice_table", ->
      thead ->
        tr ->
          td "Rank"
          td "Account"
          td "Submissions"

      for rank, submitter in ipairs @top_users
        user = submitter.user
        tr ->
          td rank
          td ->
            a href: @url_for(user), user\name_for_display!

          td @number_format submitter.count

  render_new_streaks: =>
    h3 "New streaks created in the past #{@days} days"

    element "table", class: "nice_table", ->
      thead ->
        tr ->
          td "Streak"
          td "Category"
          td "Creator"
          td "Rate"
          td "Duration"
          td "Participants"

      for streak in *@new_streaks
        should_hide = streak\is_hidden! or streak\is_draft!

        unless @current_user and @current_user\is_admin!
          continue if should_hide

        tr ->
          td ->
            a href: @url_for(streak), streak.title

            if should_hide
              text " "
              em class:"sub", "(Hidden)"

          td ->
            category_name = Streaks.categories[streak.category]
            slug = BrowseStreaksFlow.category_slugs[category_name]

            a {
              href: @url_for("streaks") .. "/#{slug}"
              BrowseStreaksFlow.category_names[category_name]
            }

          td ->
            user = streak\get_user!
            a href: @url_for(user), user\name_for_display!

          td Streaks.rates[streak.rate]
          td @plural math.floor(streak\duration!), "day", "days"
          td @plural streak\approved_participants_count!, "participant", "participants"

