StreakHeader = require "widgets.streak_header"

class StreakUnitSubmitUrl extends require "widgets.page"
  inner_content: =>
    widget StreakHeader

    div class: "responsive_column", ->
      @column_content!

  column_content: =>
    if @users
      h3 ->
        text "Generate submit URL for "
        a href: @url_for("view_streak_unit", id: @streak.id, slug: @streak\slug!, date: @params.date), @params.date
      @render_user_list!

    if @submit_url
      @render_url!
      br!

  render_url: =>
    user = @streak_user\get_user!
    p "Send this url to #{user\name_for_display!}:"

    p ->
      a href: @submit_url, @submit_url

  render_user_list: =>
    unless next @users
      p "Oops there are no users in this streak"
      return

    p "A submission URL lets a user submit to the streak for a specified date
    late. Once generated, the URL will expire in 1 week. If the user has
    already submitted they will not be able to submit again."

    h4 "Select a user"

    form method: "post", class: "form", ->
      @csrf_input!

      for user in *@users
        ul ->
          li ->
            button {
              class: "button"
              name: "user_id"
              value: user.id
              user\name_for_display!
            }




