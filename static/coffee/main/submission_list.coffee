
import {S} from "main/_pre"
import {InfiniteScroll} from "main/infinite_scroll"
import $ from "main/jquery"
import {_} from "main/global_libs"

import {createRoot} from "react-dom/client"

import SubmissionListComponents from "main/react/submission_list"

export class SubmissionList
  constructor: (el, @opts={}) ->
    @el = $ el
    @setup_comments()
    @setup_paging()
    @setup_images()

    @setup_truncation()

    @el.has_tooltips()

    @el.on "s:increment_comments", ".submission_row", (e, amount=1) =>
      btn = $(e.currentTarget).find ".comments_toggle_btn"
      new_count = btn.data("count") + amount
      btn.text _.template(btn.data("template"), S.template_settings) { count: new_count }
      btn.data "count", new_count

    @el.on "s:refresh_comments", ".submission_row", (e, callback) =>
      btn = $(e.currentTarget).find ".comments_toggle_btn"

      btn.addClass "loading"
      $.get btn.data("comments_url"), (res) =>
        btn.removeClass("loading").addClass "open"

        if res.errors
          alert res.errors.join ","
          return

        commenter = $ res.rendered
        btn.closest(".submission_row")
          .find(".submission_footer").after commenter

        if callback
          callback commenter

    @el.dispatch "click", {
      unroll_submission: (btn) =>
        inside = btn.closest(".submission_inside_content")
        btn.fadeOut => btn.remove()
        inside.animate maxHeight: inside[0].scrollHeight, =>
          inside.removeClass("truncated")

      comments_toggle_btn: (btn) =>
        return if btn.is ".locked"
        return if btn.is ".loading"

        if btn.is ".open"
          btn.closest(".submission_row")
            .find(".submission_commenter").remove()
          btn.removeClass "open"
          return

        btn.trigger "s:refresh_comments"
    }

  setup_comments: =>
    @el.dispatch "click", ".submission_comment_list", {
      delete_btn: (btn) =>
        return unless confirm "Are you sure you want to delete this comment?"

        comment = btn.closest(".submission_comment").addClass "loading"
        id = comment.data "id"
        $.post "/submission-comment/#{id}/delete", S.with_csrf(), (res) =>
          comment.slideUp =>
            comment.remove()

          btn.trigger "s:increment_comments", [-1]

      edit_btn: (btn) =>
        comment = btn.closest(".submission_comment").addClass "editing"

        body = comment.find(".user_formatted")
        drop = comment.find ".comment_editor_drop"

        unless drop.length
          drop = $('<div class="comment_editor_drop"></div>').insertAfter body
          drop.data "react-root", createRoot(drop[0])

        editor = SubmissionListComponents.CommentEditor {
          edit_url: btn.data "edit_url"
          body: comment.data("body") || body.html()
          on_save: (res) =>
            drop.data("react-root").unmount()
            drop.remove()
            comment.replaceWith res.rendered

          on_cancel: =>
            drop.data("react-root").unmount()
            drop.remove()
            comment.removeClass "editing"
        }

        drop.data("react-root").render editor

      reply_btn: (btn) =>
        username = btn.closest(".submission_comment").data "author"
        editor = btn.closest(".submission_commenter").find ".comment_form_outer .markdown_editor"
        editor_component = editor.data "react_component"


        editor_component.set_markdown "#{editor_component.state.markdown}@#{username} "
        editor_component.focus()

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
    }

    @el.remote_submit ".comment_form", (res, form) =>
      if res.errors
        form.set_form_errors res.errors
        return

      form.find(".markdown_editor").data("react_component").set_markdown("")

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
          , 500

  setup_truncation: (container=@el) ->
    items = container.find ".submission_inside_content"

    add_unroll = (el) ->
      return unless el.is ".truncated"
      if el[0].scrollHeight > Math.ceil(el.height())
        unroll = el.find ".unroll_submission"
        return if unroll.length
        el.append '<div class="unroll_submission">View rest ↓</div>'

    for item in items
      do (item) ->
        item = $(item)
        add_unroll item
        item.find("img").on "load", =>
          add_unroll item

  setup_paging: =>
    scroller = new InfiniteScroll @el, {
      get_next_page: =>
        load_els = @el.add(scroller.loading_row).addClass "loading"
        @opts.page += 1

        $.get "", { page: @opts.page, format: "json" }, (res) =>
          load_els.removeClass "loading"

          if res.rendered
            new_items = $ res.rendered

            scroller.loading_row.before new_items
            @setup_truncation new_items
            @setup_images()

          unless res.has_more
            scroller.remove_loader()

    }

  setup_images: =>
    @el.lazy_images {
      selector: ".submission_row"
    }


