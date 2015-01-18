
class S.SubmissionList
  constructor: (el) ->
    @el = $ el
    @setup_comments()

    @el.dispatch "click", {
      toggle_like_btn: (btn) =>
        return "continue" unless S.current_user?

        btn.addClass ".disabled"
        url_key = if btn.is(".liked") then "unlike_url" else "like_url"
        url = btn.data url_key

        $.post url, S.with_csrf(), (res) =>
          btn.removeClass ".disabled"
          if res.success
            btn.toggleClass "liked"

          if res.count?
            btn.closest(".like_row")
              .toggleClass("has_likes", res.count > 0)
              .find(".like_count").text res.count

    }

  setup_comments: =>
    @el.dispatch "click", ".comment_list", {
      delete_btn: (btn) =>
        comment = btn.closest(".submission_comment").addClass "loading"
        id = comment.data "id"
        $.post "/submission-comment/#{id}/delete", S.with_csrf(), (res) =>
          comment.slideUp => comment.remove()
    }

    S.redactor @el.find("textarea"), minHeight: 100

    @el.remote_submit ".comment_form", (res, form) =>
      if res.errors
        form.set_form_errors res.errors
        return

      if $.fn.redactor?
        form.find("textarea").redactor "code.set", ""
      else
        form.find("textarea").val("")

      if res.rendered
        list = form.closest(".submission_row").find ".comment_list"
        new_comment = $(res.rendered).prependTo list
        height = new_comment.height()

        spacer = $ "<div class='comment_spacer'></div>"
        spacer.insertAfter(new_comment).height(0).append new_comment

        _.defer =>
          spacer.height(height).addClass "animated"

