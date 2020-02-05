
class AdminStreaks extends require "widgets.admin.page"
  column_content: =>
    h2 "Admin"

    p ->
      ul ->
        li ->
          a href: @url_for("admin.streaks"), "Streaks"
          
        li ->
          a href: @url_for("admin.comments"), "Comments"

        li ->
          a href: @url_for("admin.community_posts"), "Community Posts"



