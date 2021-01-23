import Streaks, SpamScans from require "models"

class AdminSpamQueue extends require "widgets.admin.page"
  @needs: {"user"}
  @include "widgets.form_helpers"
  @include "widgets.table_helpers"

  responsive: true

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
          "email"
          "created_at"
          "streaks_count"
          "submissions_count"
          ":is_suspended"
          ":is_spam"
        }

      section ->
        strong "Streaks"
        @column_table @user\get_created_streaks!, {
          {"streak", (streak) ->
            a href: @url_for(streak), streak.title
          }
          "users_count"
          "submissions_count"
          {"publish_status", Streaks.publish_statuses}
          "deleted"
        }

      if rr = @user\get_register_captcha_result!
        section ->
          strong "Recaptcha result"
          @field_table rr.data, {
            "hostname"
            "score"
          }

    scan = @user\get_spam_scan!

    if scan
      section ->
        strong "Scan"
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

    form method: "post", class: "form admin_columns", ->
      @csrf_input!

      unless scan and scan\is_trained!
        button  {
          class: "button"
          name: "action"
          value: "refresh"
        }, "Refresh spam scan"
        text " "

      if scan and not scan\is_reviewed!
        details class: "toggle_form", ->
          summary "Dismiss scan as safe"
          button  {
            class: "button"
            name: "action"
            value: "dismiss"
          }, "Dismiss scan as safe..."
        text " "

      if scan and not scan\is_trained! and not scan\is_reviewed!
        details class: "toggle_form", ->
          summary "Dismiss scan as SPAM"

          button  {
            class: "button red"
            name: "action"
            value: "dismiss_as_spam"
            title: "This will mark as reviewed and update the user flag to be spam"
          }, "Dismiss scan as SPAM..."


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

      render_score = (score) ->
        if score
          code title: score, "%0.4f"\format score
        else
          code "∅"

      if @user_token_summary
        section ->
          div ->
            strong "User tokens"
            text " score: "
            render_score @user_token_score

          @render_token_summary @user_token_summary, (t) ->
            a href: @url_for("admin.users", nil, user_token: t), t

      section class: "admin_columns", ->
        if @text_token_summary
          section ->
            div ->
              strong "Text tokens"
              text " score: "
              render_score @text_token_score

            @render_token_summary @text_token_summary

        section ->
          strong "Text"
          texts = SpamScans\user_texts @user
          @column_table [{:text} for text in *texts], {
            "text"
          }

  render_token_summary: (summary, url) =>
    @column_table summary, {
      {"token", (t) ->
        if url
          url t.token
        else
          text t.token
      }
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
