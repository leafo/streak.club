
P = R.package "SubmissionList"

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
      @props.show_comments?()

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
      p {}, "Help keep their streak going with some words of encouragement or some critical feedback."

      form class: "form quick_comment_form", method: "post", action: @props.comment_url,
        if @state.errors
          ul class: "form_errors",
            @state.errors.map (e) => li key: e, e
        input type: "hidden", name: "csrf_token", value: S.get_csrf()
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

P "LikeButton", {
  # propTypes: {
  #   like_url: types.string
  #   unlike_url: types.string
  #   like_count: types.number
  #   current_like: types.object
  # }
  
  getInitialState: ->
    _.pick @props, "likes_count", "current_like"

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
          show_quick_comment: current_like
          current_like
        }, ->
          $(btn).trigger "i:refresh_tooltip"

  render: ->
    [
      button {
        type: "button"
        disabled: @state.loading || false
        class: classNames "like_button", {
          has_likes: @state.likes_count > 0
          liked: @state.current_like
        }
        "data-tooltip": if @state.current_like then "Unlike submission" else "Like submission"
        onClick: @toggle_like
      },
        span class: "icon-heart"

      if @state.likes_count
        a {
          href: @props.likes_url
          class: "likes_count"
          "data-tooltip": "See likes"
        }, @state.likes_count || 0
      
      if @state.show_quick_comment and @props.comment_url
        P.QuickComment {
          comment_url: @props.comment_url
          close: =>
            @setState show_quick_comment: false
          show_comments: =>
            console.log "not yet!"
        }
    ]
}

