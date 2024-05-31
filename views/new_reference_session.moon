

class NewReferenceSession extends require "widgets.page"
  inner_content: =>
    div class: "inner_column", ->
      form method: "POST", ->
        @csrf_input!
        button {
          class: "button"
          type: "submit"
          "Start a new reference session"
        }

      if next @previous_sessions
        section class: "reference_session_list", ->
          h2 "Previous sessions"
          ul ->
          for session in *@previous_sessions
            li ->
              a href: @url_for(session), session\name_for_display!
              text " "
              span {
                class: "session_time"
                title: session.created_at
              }, @relative_timestamp session.created_at



