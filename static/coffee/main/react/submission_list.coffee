
P = R.package "SubmissionList"

P "QuickComment", {
  render: ->
    div class: "quick_comment_widget",
      h3 {}, "Like it? Leave a comment"
      p {}, "Give some additional motivation with some words of encouragement or maybe some critical feedback."
      form class: "form",
        div class: "markdown_editor",
          R.EditSubmission.Editor {
            show_format_help: false
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
      
      if @state.show_quick_comment
        P.QuickComment {
        }
    ]
}

