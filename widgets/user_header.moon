
class UserHeader extends require "widgets.base"
  @needs: {"user"}
  @include "widgets.tabs_helpers"
  @include "widgets.follow_helpers"

  widget_classes: =>
    {super!, "tab_header"}

  inner_content: =>
    section class: "page_header", ->
      div class: "header_split", ->
        div ->
          h2 @user\name_for_display!

          div class: "user_stats", ->
            div class: "user_stat", ->
              text "A member registered "
              span title: @user.created_at, @relative_timestamp @user.created_at

            if @user.comments_count > 0
              div class: "user_stat",
                @plural @user.comments_count, "comment", "comments"

            if @user.likes_count > 0
              div class: "user_stat",
                @plural @user.likes_count, "like", "likes"

        if not @current_user or @current_user.id != @user.id
          @follow_button @user, @following


    div class: "page_tabs", ->
      div class: "tabs_inner", ->
        @insert_tab! if @insert_tab

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
        if streaks_count > 0
          @page_tab "Streaks hosted",
            "streaks_hosted",
            @url_for("user_streaks_hosted", slug: @user.slug),
            "(#{streaks_count})"

        @page_tab "Tags", "tags", @url_for("user_tags", slug: @user.slug)

