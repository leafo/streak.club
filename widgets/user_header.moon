
class UserHeader extends require "widgets.base"
  @needs: {"user"}
  @include "widgets.tabs_helpers"

  base_widget: false

  inner_content: =>
    div class: "page_header", ->
      h2 @user\name_for_display!
      h3 ->
        div class: "user_stat", ->
          text "A user registered #{@relative_timestamp @user.created_at}"

        if @user.comments_count > 0
          div class: "user_stat",
            @plural @user.comments_count, "comment", "comments"

        if @user.likes_count > 0
          div class: "user_stat",
            @plural @user.likes_count, "like", "likes"

    div class: "page_tabs", ->
      @page_tab "Profile", "profile", @url_for(@user)

      if @user.following_count > 0
        @page_tab "Following",
          "following",
          @url_for("user_following", slug: @user.slug),
          "(#{@user.following_count})"

      if @user.followers_count > 0
        @page_tab "Followers",
          "followers",
          @url_for("user_followers", slug: @user.slug),
          "(#{@user.followers_count})"

      streaks_count = @user\streaks_count_for @current_user
      if streaks_count
        @page_tab "Streaks hosted",
          "streaks_hosted",
          @url_for("user_streaks_hosted", slug: @user.slug),
          "(#{streaks_count})"

