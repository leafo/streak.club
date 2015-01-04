
class ViewStreakUnit extends require "widgets.base"
  @needs: {"streak"}

  inner_content: =>
    if @streak\allowed_to_edit @current_user
      div class: "admin_tools", ->
        a href: @url_for("edit_streak", id: @streak.id), "Edit streak"
        text " "
        a href: "", "Generate late submit url"

    p ->
      a href: @url_for(@streak), "Return to streak"

    h2 @streak.title
    h3 "Unit description"
