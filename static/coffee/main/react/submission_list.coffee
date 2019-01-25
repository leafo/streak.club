
P = R.package "SubmissionList"

P "CommentEditor", {
  getInitialState: -> {}

  componentDidMount: ->
    $(@refs.form).remote_submit (res) =>
      @setState loading: false

      if res.errors
        @setState errors: res.errors
      else
        @props.on_save? res

  render: ->
    div className: "comment_editor",
      form {
        ref: "form"
        action: @props.edit_url
        className: "form edit_comment_form"
        method: "post"

        onSubmit: (e) =>
          if @state.loading
            e.preventDefault()
            e.stopPropagation()
            return

          @setState loading: true, errors: null
      },
        if @state.errors
          ul className: "form_errors",
            @state.errors.map (error) =>
              li key: error, error

        input type: "hidden", name: "csrf_token", value: S.get_csrf()
        div className: "input_wrapper",
          div className: "markdown_editor",
            R.EditSubmission.Editor {
              required: true
              autofocus: true
              placeholder: "Your comment"
              name: "comment[body]"
              value: @props.body || ""
            }

        div className: "button_row",
          button {
            className: classNames "button", disabled: @state.loading
            disabled: @state.loading
          }, "Update comment"
          " or "
          a {
            className: "cancel_edit_btn"
            href: "javascript:void(0)"
            onClick: (e) =>
              e.preventDefault()
              @props.on_cancel?()
          }, "Cancel"
}


P "QuickComment", {
  getInitialState: -> { }

  componentDidMount: ->
    el = $ ReactDOM.findDOMNode @

    if @props.close
      @autoclose = (e) =>
        return if $(e.target).closest(el).length
        # partial comment typed
        return if @comment_editor?.state.markdown.length

        @props.close()

      $(document.body).on "click", @autoclose

    el.remote_submit ".quick_comment_form", (res, form) =>
      if res.errors
        @setState {
          errors: res.errors
        }
        return

      @props.close?()
      @props.on_comment_added?(res)

  componentWillUnmount: ->
    if @autoclose
      $(document.body).off "click", @autoclose

  render: ->
    div class: "quick_comment_widget",
      button {
        class: "close_button"
        onClick: (e) =>
          @props.close?()
      }, "×"

      h3 {}, "Like it? Leave a comment"
      p {}, "Help keep their streak going with some words of encouragement or some feedback."

      form class: "form quick_comment_form", method: "post", action: @props.comment_url,
        if @state.errors
          ul class: "form_errors",
            @state.errors.map (e) => li key: e, e
        input type: "hidden", name: "csrf_token", value: S.get_csrf()
        input type: "hidden", name: "comment[source]", value: "quick"
        div class: "markdown_editor",
          R.EditSubmission.Editor {
            name: "comment[body]"
            requried: true
            ref: (@comment_editor) =>
            show_format_help: false
            on_key_down: (e) =>
              if e.keyCode == 27
                @props.close()

              return

            autofocus: true
          }
        button class: "button small", "Submit comment"
}

P "LikeButtonProvider", {
  pure: true
  # propTypes: {
  #   submission_id: types.number
  #   render_with_props: types.function
  # }

  componentDidMount: ->
    return unless @props.submission_id
    $.get "/submission/#{@props.submission_id}/like", (res) =>
      @setState props: res

  render: ->
    @props.render_with_props(@state?.props)
}

P "LikeButton", {
  # propTypes: {
  #   submission_id: types.number
  #   like_url: types.string
  #   unlike_url: types.string
  #   like_count: types.number
  #   current_like: types.object
  # }

  getDefaultProps: ->
    {
      quick_comment: true
      show_count: true
    }

  getInitialState: ->
    _.pick @props, "likes_count", "current_like"

  on_update_like: (e, component, submission_id, update) ->
    return if component == @
    return unless @props.submission_id == submission_id
    @setState update

  componentDidMount: ->
    el = ReactDOM.findDOMNode @
    $(document.body).on "s:update_like", @on_update_like

  componentWillUnmount: ->
    $(document.body).off "s:update_like", @on_update_like

  toggle_like: (e) ->
    unless S.current_user?
      window.location = @props.login_url
      return

    return if @state.loading

    url = if @state.current_like
      @props.unlike_url
    else
      @props.like_url

    btn = e.currentTarget

    @setState loading: true

    $.post url, S.with_csrf(), (res) =>
      @setState loading: false
      if res.success
        current_like = !@state.current_like

        @setState {
          loading: false
          likes_count: res.count
          show_quick_comment: @props.quick_comment && !S.is_mobile() && current_like
          current_like
        }, ->
          $(document.body).trigger "s:update_like", [@, @props.submission_id, {
            likes_count: @state.likes_count
            current_like: @state.current_like
          }]

          $(btn).trigger "i:refresh_tooltip"

  render: ->
    [
      button {
        type: "button"
        disabled: @state.loading || false
        class: classNames "like_button", {
          loading: @state.loading
          has_likes: @state.likes_count > 0
          liked: @state.current_like
        }
        "data-tooltip": if @state.current_like then "Unlike submission" else "Like submission"
        onClick: @toggle_like
      },
        @props.icon || span class: "icon-heart"

      if @props.show_count and @state.likes_count
        a {
          href: @props.likes_url
          class: "likes_count"
          "data-tooltip": "See likes"
        }, @state.likes_count || 0

      if @props.quick_comment and @state.show_quick_comment and @props.comment_url
        P.QuickComment {
          comment_url: @props.comment_url
          close: =>
            @setState show_quick_comment: false

          on_comment_added: (res) =>
            submission_row = $(".submission_row[data-submission_id=#{@props.submission_id}]")
            submission_row.trigger "s:increment_comments"
            submission_row.trigger "s:refresh_comments", [
              (comment_list) =>
                comment = comment_list.find(".submission_comment[data-id=#{res.comment_id}]")
                comment[0]?.scrollIntoView?()
            ]
        }
    ]
}

