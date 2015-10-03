
StreakHeader = require "widgets.streak_header"

class StreakEmbed extends require "widgets.page"
  @needs: {"streak"}

  inner_content: =>
    widget StreakHeader page_name: "embed"

    div class: "responsive_column", ->
      h3 "Embed streak"
      p ->
        text "If you'd like to embed a streak on another page you can do so by
        using the following "
        code "iframe"
        text " embed code. Just paste in the HTML of your blog or site."

      div class: "columns form", ->
        div class: "embed_inputs", ->
          label ->
            div class: "label", "Code"
            textarea readonly: true, capture ->
              iframe {
                frameborder: 0
                width: 400
                height: 500
                src: @build_url @url_for(@streak) .. "?embed=true"
              }

        div class: "example", ->
          div class: "label", "Preview"
          iframe {
            frameborder: 0
            width: 400
            height: 500
            src: @url_for(@streak) .. "?embed=true"
          }

