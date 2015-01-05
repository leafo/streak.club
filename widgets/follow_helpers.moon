import login_and_return_url from require "helpers.app"

class FollowHelpers
  follow_button: (user, following) =>
    classes = "button toggle_follow_btn"
    classes ..= " logged_out" unless @current_user
    classes ..= " following" if following

    a {
      href: @current_user and "#" or login_and_return_url @
      "data-follow_url": @url_for "user_follow", id: user.id
      "data-unfollow_url": @url_for "user_unfollow", id: user.id
      class: classes
    }, ->
      span class: "on_not_following", ->
        text "Follow #{user\name_for_display!}"

      span class: "on_following", ->
        text "Unfollow #{user\name_for_display!}"
