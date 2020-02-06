PostForm = require "widgets.community.post_form"

class CommunityTopicHelpers
  topic_posts_pager: (classes, always_show=false) =>
    unless always_show
      return unless @next_page or @prev_page

    div class: "topic_pager #{classes or ""}", ->
      span class: "page_label", ->
        first = @posts[1]
        last = @posts[#@posts]

        if first and last
          text "Viewing #{@noun} "

          span @number_format first.post_number
          text " to "
          span @number_format last.post_number
          if @next_page or @prev_page
            text " of #{@number_format @topic.root_posts_count}"

      if @next_page
        raw " &middot; "
        a {
          href: @url_for @topic, @next_page
          class: "page_link"
          "Next page"
        }


      if @prev_page
        raw " &middot; "
        a {
          href: @url_for @topic, @prev_page
          class: "page_link"
          "Previous page"
        }

        raw " &middot; "

        a {
          href: @url_for(@topic)
          class: "page_link"
          "First page"
        }

  topic_lock_message: =>
    return unless @topic.locked
    if lock_log = @topic\get_lock_log!
      locking_user = lock_log\get_user!

      text "This topic was locked by "
      a href: @community_url_for(locking_user), locking_user\name_for_display!
      text " "
      @date_format lock_log.created_at
    else
      text "This topic is locked"


