

class StreakUnitSubmitUrl extends require "widgets.base"
  inner_content: =>
    div class: "page_header", ->
      h2 "Generate submit URL for #{@params.date}"
      h3 ->
        a href: @url_for(@streak), @streak.title

    br!

    if @users
      @render_user_list!

    if @submit_url
      @render_url!

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
    at any time. Once generated, the URL will expire in 1 week. If the user has
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




