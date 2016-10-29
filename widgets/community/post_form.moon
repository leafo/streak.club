import to_json from require "lapis.util"

class CommunityPostForm extends require "widgets.base"
  @include "widgets.form_helpers"
  @needs: {"post", "topic"}

  post_label: "Post"
  save_label: "Save"
  redactor_opts: nil
  subscribe_checkbox: true
  show_author: false

  widget_classes: =>
    { super!, show_authow: @show_author }

  js_init: =>
    redactor_opts = @redactor_opts

    if cat = not redactor_opts and @topic\get_category!
      redactor_opts = cat\edit_options!.redactor_opts

    opts = {
      focus: @focus
      :redactor_opts
    }

    nil

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

      @text_input_row {
        label: "Body"
        name: "post[body]"
        type: "textarea"
        placeholder: "Required"
        value: @post and @post.body
      }

      if @editing and @post\is_topic_post! and not @topic.permanent
        available_tags = @topic\get_category!\get_tags!

        if next available_tags
          tags = @topic\get_tags!
          current_tag = tags and tags[1] and tags[1].slug
          tags = [{tag.slug, tag\name_for_display!} for tag in *available_tags]
          if current_tag
            table.insert tags, {"", -> em "Remove tag"}

          @input_row "Tag", ->
            @radio_buttons "post[tags]", tags, current_tag

      if @show_subscribe_checkbox!
        @input_row "Subscribe", ->
          @checkboxes {
            {"subscribe", "Subscribe to this topic", "Get notifications of new replies to the topic"}
          }

      div class: "buttons", ->
        button class: "button", ->
          if @editing
            text @save_label
          else
            text @post_label

