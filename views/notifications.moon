
import time_ago_in_words from require "lapis.util"

class Notifications extends require "widgets.base"
  @needs: {"global_notifications", "old_notifications"}

  inner_content: =>
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
        object = notification.object
        div class: "notification_row", ->
          unless object
            text "Unknown notification, oops!"
            return

          text notification\prefix!
          text " "
          a href: @url_for(object), notification\object_title!
          text " "
          span {
            class: "timestamp"
            title: "#{notification.created_at} UTC"
            time_ago_in_words notification.created_at
          }


