
StreakHeader = require "widgets.streak_header"
UserList = require "widgets.user_list"

class StreakTopParticipants extends require "widgets.page"
  @needs: {"active_top_streak_users", "top_streak_users"}

  page_name: "top_participants"

  inner_content: =>
    widget StreakHeader page_name: @page_name

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    unless next @top_streak_users
      p class: "empty_message", "There don't appear to be any submission streaks"
      return

    if next @active_top_streak_users
      h3 "Longest active streak"
      widget UserList @list_params @active_top_streak_users

    h3 "Longest streak"
    widget UserList @list_params @top_streak_users

  list_params: (sus) =>
    su_by_user = {su.user, su for su in *sus}

    {
      users: [su.user for su in *sus]
      user_stats: (user) =>
        su = su_by_user[user]

        span class: "user_stat",
          "longest streak: #{su\get_longest_streak!}"

        span class: "user_stat",
          "current streak: #{su\get_current_streak!}"

        span class: "user_stat",
          @plural su.submissions_count, "submission", "submissions"

    }


