
class S.SubmissionList
  comment_editor_template: S.lazy_template @, "comment_editor"

  constructor: (el, @opts={}) ->
    @el = $ el
    @setup_comments()
    @setup_paging()

    @setup_truncation()

    @el.has_tooltips()

    @el.find(".submission_content img").load =>
      @el.trigger "s:reshape"

    @el.on "s:increment_comments", ".submission_row", (e, amount=1) =>
      btn = $(e.currentTarget).find ".comments_toggle_btn"
      new_count = btn.data("count") + amount
      btn.text _.template(btn.data("template")) { count: new_count }
      btn.data "count", new_count

    @el.dispatch "click", {
      unroll_submission: (btn) =>
        inside = btn.closest(".submission_inside_content")
        btn.fadeOut => btn.remove()
        inside.animate maxHeight: inside[0].scrollHeight, =>
          inside.removeClass("truncated")

      play_audio_btn: (btn) =>
        audio_row = btn.closest ".submission_audio"
        return if audio_row.is ".loading"
        url = btn.data "audio_url"

        if audio_row.is ".playing"
          audio_row.data("audio").pause()
          audio_row.removeClass "playing"
          return

        if audio_row.is ".loaded"
          audio_row.data("audio").play()
          btn.trigger "s:play_audio", [btn]
          audio_row.addClass "playing"
          return


        unless btn.is ".listener_bound"
          btn.addClass "listener_bound"

          $(document).on "s:play_audio", (e, el) =>
            return if el.is btn
            audio_row.data("audio")?.pause()

        audio_row.addClass "loading"
        $.post url, S.with_csrf(), (res) =>
          progress_bar = audio_row.find ".audio_progress_inner"
          progress_bar.width "0%"

          audio = document.createElement "audio"

          unless audio.canPlayType "audio/mpeg"
            alert "Yikes, doesn't look like your browser supports playing MP3s"
            return

          audio.setAttribute "src", res.url
          audio.play()
          btn.trigger "s:play_audio", [btn]
          audio_row.data "audio", audio

          audio.addEventListener "loadstart", =>

          audio.addEventListener "pause", =>
            audio_row.removeClass "playing"

          audio.addEventListener "timeupdate", =>
            audio_row.removeClass("loading").addClass "playing loaded"
            progress_bar.width "#{audio.currentTime / audio.duration * 100}%"

          audio.addEventListener "ended", =>
            audio_row.removeClass "loaded playing"


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

      comments_toggle_btn: (btn) =>
        return if btn.is ".locked"
        return if btn.is ".loading"

        if btn.is ".open"
          btn.closest(".submission_row")
            .find(".submission_commenter").remove()
          btn.removeClass "open"
          return

        btn.addClass "loading"
        $.get btn.data("comments_url"), (res) =>
          btn.removeClass("loading").addClass "open"

          if res.errors
            alert res.errors.join ","
            return

          commenter = $ res.rendered
          btn.closest(".submission_row")
            .find(".submission_footer").after commenter

          S.with_redactor =>
            S.redactor commenter.find("textarea"), minHeight: 100

          @el.trigger "s:reshape"
    }

  setup_comments: =>
    textareas = @el.find("textarea")
    if textareas.length
      S.redactor textareas, minHeight: 100

    @el.dispatch "click", ".submission_comment_list", {
      delete_btn: (btn) =>
        return unless confirm "Are you sure you want to delete this comment?"

        comment = btn.closest(".submission_comment").addClass "loading"
        id = comment.data "id"
        $.post "/submission-comment/#{id}/delete", S.with_csrf(), (res) =>
          comment.slideUp =>
            comment.remove()
            @el.trigger "s:reshape"

          btn.trigger "s:increment_comments", [-1]

      edit_btn: (btn) =>
        comment = btn.closest(".submission_comment").addClass "editing"

        id = comment.data "id"
        body = comment.find(".user_formatted")

        editor = $ @comment_editor_template {
          id: id
          body: comment.data("body") || body.html()
        }

        body.replaceWith editor
        @el.trigger "s:reshape"
        S.redactor editor.find("textarea"), minHeight: 100

        editor.dispatch "click", {
          cancel_edit_btn: (btn) =>
            editor.replaceWith body
            comment.removeClass "editing"
            @el.trigger "s:reshape"
        }

      reply_btn: (btn) =>
        username = btn.closest(".submission_comment").data "author"
        editor = btn.closest(".submission_commenter").find ".comment_form_outer textarea"
        editor.redactor "insert.html", "@#{username}&nbsp;"

        outer = editor.closest ".comment_form_outer"
        outer[0].scrollIntoView?()

    }

    @el.dispatch "click", ".submission_commenter", {
      load_more_btn: (btn) =>
        return if btn.is ".loading"
        btn.addClass "loading"

        page = btn.data("page")
        page += 1
        btn.data "page", page

        $.get btn.data("href"), { page: page }, (res) =>
          btn.removeClass "loading"
          commenter = btn.closest(".submission_commenter")

          if res.rendered
            comments = $ res.rendered
            commenter.find(".submission_comment_list").append comments

          unless res.has_more
            commenter.find(".load_more_btn").remove()

          @el.trigger "s:reshape"
    }

    @el.remote_submit ".edit_comment_form", (res, form) =>
      if res.errors
        form.set_form_errors res.errors
        return

      if res.rendered
        form.closest(".submission_comment").replaceWith $ res.rendered
        @el.trigger "s:reshape"

    @el.remote_submit ".comment_form", (res, form) =>
      if res.errors
        form.set_form_errors res.errors
        return

      if $.fn.redactor?
        form.find("textarea").redactor "code.set", ""
      else
        form.find("textarea").val("")

      if res.rendered
        form.trigger "s:increment_comments", [1]
        list = form.closest(".submission_row").find ".submission_comment_list"
        new_comment = $(res.rendered).prependTo list
        height = new_comment.height()

        spacer = $ "<div class='comment_spacer'></div>"
        spacer.insertAfter(new_comment).height(0).append new_comment

        _.defer =>
          spacer.height(height).addClass "animated"
          setTimeout =>
            spacer.replaceWith new_comment
            @el.trigger "s:reshape"
          , 500

  setup_truncation: (content=@el.find ".submission_inside_content")=>
    add_unroll = (el) ->
      return unless el.is ".truncated"
      if el[0].scrollHeight > el.height()
        unroll = el.find ".unroll_submission"
        return if unroll.length
        el.append '<div class="unroll_submission">View rest ↓</div>'

    for item in content
      do (item) ->
        item = $(item)
        add_unroll item
        item.find("img").load =>
          add_unroll item

  setup_paging: =>
    scroller = new S.InfiniteScroll @el, {
      get_next_page: =>
        load_els = @el.add(scroller.loading_row).addClass "loading"
        @opts.page += 1

        $.get "", { page: @opts.page, format: "json" }, (res) =>
          load_els.removeClass "loading"

          unless res.has_more
            scroller.remove_loader()

          if res.rendered
            new_items = $ res.rendered
            @el.find(".submission_list").append new_items
            @el.trigger "s:reshape"
            new_items.find(".submission_content img").load => @el.trigger "s:reshape"
    }

