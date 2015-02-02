import Widget from require "lapis.html"

class Email extends Widget
  @include "widgets.helpers"

  @render: (r, params) =>
    i = @(params)
    i\include_helper r
    i\subject!, i\render_to_string!, html: true

  @send: (r, recipient, widget_opts, email_opts) =>
    import send_email from require "email"
    email_opts or= html: true
    subject, body = @render r, widget_opts
    send_email recipient, subject, body, email_opts

  url_for: (...) =>
    url_for = @_find_helper "url_for"
    @build_url url_for nil, ...

  subject: => "Streak Club"

  content: =>
    bg_color = "#e8e8e8"
    body style: "background-color: #{bg_color}", ->
      element "table", style: "background-color: #{bg_color}; width: 100%", cellspacing: "0", cellpadding: "0", ->
        tr ->
          td style:"text-align: center; padding-top: 30px;", ->
            a href: "http://streak.club", ->
              img src: "http://streak.club/static/images/favicon.png", border: "0"
        tr ->
          td ->
            element "table", style: @container_style!, ->
              tr ->
                td style: "padding: 20px;", ->
                  div -> @body!
                  @hr!
                  @footer!

  body: => error "fill me out"

  container_style: =>
    "background-color: white; max-width: 600px; margin: 10px auto 40px auto;border-radius: 2px; border: 1px solid #dadada;"

  footer: =>
    h4 ->
      text "powered by "
      a href: "http://streka.club", "Streak Club"

    if @show_tag_unsubscribe
      div style: "color: #666666; font-size: smaller", ->
        text "Don't want to receive emails like this? "
        a href: "%tag_unsubscribe_url%", style: "color: #666", "Unsubscribe"

  hr: =>
    hr style: "border: 0; height: 1px; background: #dadada"

