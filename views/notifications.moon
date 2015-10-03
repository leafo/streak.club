
import time_ago_in_words from require "lapis.util"

class Notifications extends require "widgets.page"
  @needs: {"global_notifications", "old_notifications"}

  column_content: =>
    div class: "page_header", ->
      h2 ->
        text "Notifications"

    if #@global_notifications > 0
      h3 "New"
      @render_notifications @global_notifications

    if #@old_notifications > 0
      h3 "Old"
      @render_notifications @old_notifications
 
  render_notifications: (nots) =>
    div class: "notification_list", ->
      for notification in *nots
        nos = notification.notification_objects

        object = notification.object
        div class: "notification_row", ["data-notification_id"]: notification.id, ->
          unless object
            text "Unknown notification, oops!"
            return

          if notification\show_join_usernames!
            for i, no in ipairs nos
              text ", " if i > 1
              user = no\get_object!
              a href: @url_for(user), user\name_for_display!

            text " joined"
          else
            text notification\prefix!

          text " "
          a href: @url_for(object), notification\object_title!
          text " "

          span {
            class: "timestamp"
            title: "#{notification.created_at} UTC"
            time_ago_in_words notification.created_at
          }


