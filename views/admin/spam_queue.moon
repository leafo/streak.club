import SpamScans from require "models"

-- a lot of this is copied from the user admin page just to quickly get this
-- together

class AdminSpamQueue extends require "widgets.admin.page"
  @needs: {"user"}
  @include "widgets.form_helpers"
  @include "widgets.table_helpers"


  column_content: =>
    div class: "page_header", ->
      h2 "Spam Queue"
      p ->
        a href: @url_for("admin.spam_queue"), "top"

    div class: "admin_columns", ->
      section ->
        strong "User"
        @field_table @user, {
          "id"
          {"username", (user) ->
            a href: @url_for(user), user.username
            text " ("
            a href: @admin_url_for(user), "Admin"
            text ")"
          }

          ":name_for_display"
          "streaks_count"
          "submissions_count"
          ":is_suspended"
          ":is_spam"
        }

      section ->
        strong "Streaks"
        @column_table @user\get_streak_users!, {
          {"streak", (su) ->
            streak = su\get_streak!
            a href: @url_for(streak), streak.title
          }
          "submissions_count"
          "last_submitted_at"
          "created_at"
          "pending"
        }

      if rr = @user\get_register_captcha_result!
        section ->
        h3 "Recaptcha result"
        @field_table rr.data, {
          "hostname"
          "score"
        }

    scan = @user\get_spam_scan!

    if scan
      @field_table scan, {
        {"score", (scan) ->
          if scan.score
            code title: scan.score, "%0.4f"\format scan.score
          else
            code class: "sub", "∅"
        }
        {"review_status", SpamScans.review_statuses}
        {"train_status", SpamScans.train_statuses}
        "created_at", "updated_at"
      }
    else
      p ->
        em "This user has no spam scan"

    form method: "post", class: "form", ->
      @csrf_input!

      unless scan and scan\is_trained!
        button  {
          class: "button"
          name: "action"
          value: "refresh"
        }, "Refresh spam scan"
        text " "

      if scan and scan\needs_review!
        button  {
          class: "button"
          name: "action"
          value: "dismiss"
        }, "Dismiss scan as safe"
        text " "

      if scan and not scan\is_trained! and not scan\is_reviewed!
        button  {
          class: "button red"
          name: "action"
          value: "dismiss_as_spam"
          title: "This will mark as reviewed and update the user flag to be spam"
        }, "Dismiss scan as SPAM"
        text " "


    if not scan or not scan\is_trained!
      form method: "post", class: "form", ->
        @csrf_input!
        input type: "hidden", name: "action", value: "train"
        fieldset ->
          legend "Train spam"

          button {
            name: "train"
            class: "button green"
            value: "ham"
          }, "Ham"
          text " "

          label ->
            input type: "checkbox", name: "confirm", required: true
            text " Confirm"

          text " "

          button {
            name: "train"
            class: "button red"
            value: "spam"
          }, "Spam"

    fieldset ->
      legend "Spam tokens"

      if @user_token_summary
        h3 "User tokens"
        @render_token_summary @user_token_summary

      section class: "admin_columns", ->
        if @text_token_summary
          section ->
            h3 "Text tokens"
            @render_token_summary @text_token_summary

        section ->
          h3 "Text"
          texts = SpamScans\user_texts @user
          @column_table [{:text} for text in *texts], {
            "text"
          }

  render_token_summary: (summary) =>
    @column_table summary, {
      "token"
      {"category", (t) ->
        if top = unpack(t.counts)
          if top.category.name\match "spam"
            strong style: "color: red", top.category.name
          else
            text top.category.name
        else
          em class: "sub", "n/a"
      }
      {"rate", (t) ->
        if top = unpack(t.counts)
          text "#{"%0.3f"\format top.p * 100}%"
      }
      {"count", (t) ->
        if top = unpack(t.counts)
          text @number_format top.count
      }
    }
