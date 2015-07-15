
class DeleteSubmission extends require "widgets.base"
  inner_content: =>
    div class: "page_header", ->
      h2 "Delete submission"
      h3 @submission.title

    p ->
      text "Are you sure you want to delete your submission "
      em @submission.title
      text "? Once deleted it is unrecoverable."

    form class: "form", method: "POST", ->
      div class: "button_row", ->
        button class: "button", "Delete it"
        text " or "
        a href: @url_for(@submission), "Go back"

 
