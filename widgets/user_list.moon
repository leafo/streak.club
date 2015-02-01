
class UserList extends require "widgets.base"
  @include "widgets.follow_helpers"
  @needs: {"users"}

  base_widget: false
  narrow: false

  widget_classes: =>
    classes = super!
    classes ..= " narrow" if narrow
    classes

  js_init: =>
    "new S.UserList(#{@widget_selector!})"

  inner_content: =>
    for user in *@users
      div class: "user_row", ->
        a href: @url_for(user), ->
          img src: user\gravatar!, class: "user_avatar"

        div class: "user_data", ->
          div ->
            a class: "user_name", href: @url_for(user), user\name_for_display!

          if @narrow
            div class: "user_stats", ->
              span class: "user_stat",
                @plural user.streaks_count, "streak", "streaks"
          else
            div class: "user_stats", ->
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

        unless @current_user and user.id == @current_user.id
          @follow_button user, user.following
