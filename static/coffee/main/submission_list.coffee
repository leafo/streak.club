
class S.SubmissionList
  constructor: (el) ->
    @el = $ el
    @el.dispatch "click", {
      toggle_like_btn: (btn) =>
        btn.addClass ".disabled"
        url_key = if btn.is(".liked") then "unlike_url" else "like_url"
        url = btn.data url_key

        $.post url, S.with_csrf(), (res) =>
          btn.removeClass ".disabled"
          if res.success
            btn.toggleClass "liked"
    }

