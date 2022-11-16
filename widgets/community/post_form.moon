import to_json from require "lapis.util"
MarkdownEditor = require "widgets.markdown_editor"

class CommunityPostForm extends require "widgets.base"
  @include "widgets.form_helpers"
  @needs: {"post", "topic"}

  post_label: "Post"
  save_label: "Save"
  subscribe_checkbox: true
  show_author: false

  widget_classes: =>
    { super!, show_authow: @show_author }

  @js_init: [[
    import {CommunityPostForm} from "main/community"
    new CommunityPostForm(widget_selector, widget_params)
  ]]

  js_init: =>
    super {
      focus: @focus
    }

  show_subscribe_checkbox: =>
    return false if @editing
    return false if @parent_post
    return false unless @subscribe_checkbox
    return false if @topic\is_subscribed @current_user
    true

  inner_content: =>
    if @show_author and @current_user
      div class: "reply_form_columns", ->
        div class: "author_column", ->
          a href: @url_for(@current_user), class: "avatar_container", ->
            av_url = @current_user\gravatar 80
            div {
              class: "post_avatar"
              style: "background-image: url(#{av_url})"
            }

        @render_form!
    else
      @render_form!

  render_form: =>
    action = if @editing
      @url_for "community.edit_post", post_id: @post.id
    elseif @parent_post
      @url_for "community.reply_post", post_id: @parent_post.id
    else
      @url_for "community.new_post", topic_id: @topic.id

    form {
      method: "post"
      class: "form post_form"
      action: action
    }, ->
      @csrf_input!

      if @parent_post
        input type: "hidden", name: "parent_post_id", value: @parent_post.id

      if @editing and @post\is_topic_post! and not @topic.permanent
        @text_input_row {
          label: "Title"
          name: "post[title]"
          placeholder: "Required"
          value: @post\get_topic!.title
        }

      @input_row "Body", ->
        widget MarkdownEditor {
          required: true
          name: "post[body]"
          placeholder: "Required"
          value: @post and @post.body
        }

      if @show_subscribe_checkbox!
        @input_row "Subscribe", ->
          @checkboxes {
            {"subscribe", "Subscribe to this topic", "Get notifications of new replies to the topic"}
          }, {
            subscribe: true
          }

      div class: "buttons", ->
        button class: "button", ->
          if @editing
            text @save_label
          else
            text @post_label

