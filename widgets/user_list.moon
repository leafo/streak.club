
class UserList extends require "widgets.base"
  @include "widgets.follow_helpers"
  @needs: {"users"}

  narrow: false

  widget_classes: =>
    classes = super!
    classes ..= " narrow" if @narrow
    classes

  js_init: =>
    "new S.UserList(#{@widget_selector!});"

  user_link: (user) =>
    @url_for user

  user_stats: (user) =>
    if @narrow
      span class: "user_stat",
        @plural user.streaks_count, "streak", "streaks"
    else
      span class: "user_stat",
        @plural user.followers_count, "follower", "followers"

      span class: "user_stat", "Following #{user.following_count}"

      span class: "user_stat",
        @plural user.submissions_count, "submission", "submissions"

      if user.comments_count > 0
        span class: "user_stat",
          @plural user.comments_count, "comment", "comments"

      if user.likes_count > 0
        span class: "user_stat",
          @plural user.likes_count, "like", "likes"

      if user.streaks_count > 0
        span class: "user_stat",
          @plural user.streaks_count, "streak", "streaks"

  inner_content: =>
    for user in *@users
      div class: "user_row", ->
        a href: @user_link(user), ->
          img src: user\gravatar!, class: "user_avatar"

        div class: "data_action_split", ->
          div class: "user_data", ->
            div ->
              a class: "user_name", href: @user_link(user), user\name_for_display!

            div class: "user_stats", ->
              @user_stats user

          @action_area user

  action_area: (user) =>
    unless @current_user and user.id == @current_user.id
      @follow_button user, user.following
