
P = R.package "SubmissionList"

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
        @setState {
          loading: false
          likes_count: res.count
          current_like: !@state.current_like
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
    ]
}

