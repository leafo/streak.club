
Countdown = require "widgets.countdown"
StreakList = require "widgets.streak_list"

class IndexLoggedOut extends require "widgets.page"
  @needs: {"featured_streaks"}

  responsive: true

  js_init: =>
    "new S.IndexLoggedOut(#{@widget_selector!});"

  inner_content: =>
    div class: "primary_header", ->
      h1 class: "slide_up", "Streak Club"
      h2 class: "slide_up", ->
        text "A place for "
        span class: "typed_drop"

    div class: "streak_browser page_tabs", ->
      span class: "tab_sub", "Browse:"
      @filter_tab "All streaks", "type", nil
      @filter_tab "Visual arts", "type", "visual_art", "visual-arts"
      @filter_tab "Interactive", "type", "interactive"
      @filter_tab "Music & audio", "type", "music", "music-and-audio"
      @filter_tab "Video", "type", "video"
      @filter_tab "Writing", "type", "writing"
      @filter_tab "Other", "type", "other"

    div class: "intro", ->
      div class: "intro_left", ->
        h3 "Streaks?"
        p ->
          text "A "
          em "streak"
          text " is a commitment to yourself to complete some activity every
          day or week to help improve yourself."

        p "At Streak Club you can organize or join creative streaks, streaks
        where you create art, record music, write short stories, or anything
        else you can think of."

      div class: "intro_right", ->
        img src: "/static/images/mini1.png"

    div class: "streak_grid", ->
      div class: "grid_note above",
        "When you join a streak you get a calendar of squares you need to fill:"

      div class: "grid_wrapper", ->
        for i=1,39
          div class: "grid_box"

      div class: "grid_stats", ->
        div class: "stat_value", "0"
        div class: "stat_label",  "current streak"

      div class: "grid_note below",
        "Get a green box each time you submit. Try to fill as many in a row as possible!"

    div class: "tutorial", ->
      div class: "tutorial_left", ->
        h3 "How it works"
        p "Creating a streak is simple: pick start and end dates, write some
        rules, then invite some friends (or do it solo). Don't want to create
        your own? Browse around some public streaks and join in."

      div class: "tutorial_right", ->
        h3 "Creative streaks?"
        p "That's right. Streak club is designed for doing activities that
        produce something. You're encouraged to post your results so you can
        reflect back on what you've done and see how you've improved as you streak."


    div class: "streak_countdown", ->
      div class: "countdown_note above",
        "Streak.club will keep track of what streaks need submissions and when:"

      widget Countdown {
        header_content: =>
          text "Time left to submit"

          span class: "sub",
            "day #27"
      }

      div class: "countdown_note below",
        "Try to post a submission before the countdown runs out of time."

    div class: "footer_buttons", ->
      h3 "Get started"

      div class: "buttons_box", ->
        div ->
          a {
            class: "button outline_button"
            href: @url_for("user_register")
            "Create an account"
          }

        div class: "small_text", ->
          text " or "
          a href: @url_for("user_login"), "Log in"

    if next @featured_streaks
      div class: "featured_streaks", ->
        h3 class: "sub_header", "Check out some featured streaks"

        widget StreakList {
          streaks: @featured_streaks
        }

    div class: "all_streaks", ->
      a href: @url_for("streaks"), "Browse all streaks"

    if next @featured_submissions
      div class: "featured_submissions", ->
        h3 class: "sub_header", "Featured submissions"

        div class: "submission_columns", ->
          @submission_columns @featured_submissions

  submission_columns: (submissions) =>
    grouped_submissions = {}
    cols = 3
    for i, sub in ipairs submissions
      col = (i - 1) % cols + 1
      grouped_submissions[col] or= {}
      table.insert grouped_submissions[col], sub

    for col=1,cols
      continue unless grouped_submissions[col]

      div class: "submissions_column col#{col}", ->
        for sub in *grouped_submissions[col]
          continue unless sub.streak_submissions and next sub.streak_submissions
          div class: "featured_submission", ->
            for upload in *sub.uploads
              if upload\is_image!
                div class: "submission_image", ->
                  a href: @url_for(sub), target: "_blank", ->
                    img src: @url_for upload, "600x"

              break

            div class: "submission_meta", ->
              a class: "user_link", href: @url_for(sub.user), ->
                img src: sub.user\gravatar!

              div class: "submission_title", ->
                submit = unpack sub.streak_submissions
                strong "##{submit\unit_number!}"
                text " for "
                a href: @url_for(submit.streak), submit.streak.title

              div class: "submission_author", ->
                text "by "
                a href: @url_for(sub.user), sub.user\name_for_display!

  filter_tab: (label, key, val, slug) =>
    url = @url_for "streaks"

    if slug or val
      url ..= "/#{slug or val}"

    a href: url, class: "tab", label

