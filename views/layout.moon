import Widget from require "lapis.html"

import to_json from require "lapis.util"

config = require("lapis.config").get!

class Layout extends Widget
  @include "widgets.asset_helpers"

  head: =>
    meta charset: "UTF-8"
    meta name: "robots", content: "noindex" if @noindex

    -- TODO: this stuff
    -- raw [[<meta name="msvalidate.01" content="" />]]
    -- raw [[<meta property="fb:app_id" content="" />]]


    link rel: "icon", type: "image/png", href: "/static/images/favicon.png"

    title ->
      if @title
        text "#{@title} - Streak Club"
      else
        text "Streak Club"

    meta name: "csrf_token", value: @csrf_token

    -- TODO: this stuff
    -- meta property: "og:site_name", content: "Streak Club"
    -- meta property: "twitter:account_id", content: ""

    @content_for "meta_tags"

    if @meta_description
      meta property: "og:description", content: @meta_description
      meta name: "description", content: @meta_description

    if @mobile_friendly
      meta name: "viewport", content: "width=device-width, initial-scale=1"

    @include_fonts!

  header: =>
    div class: "header", id: "global_header", ->
      div class: "primary_header", ->
        a href: @url_for("index"), class: "logo", ->
          img class: "logo_image", src: "/static/images/rainbow-sm.png"
          span class: "logo_text", "Streak Club"

      div class: "right_header", ->
        if @current_user
          a class: "user_name", href: @url_for(@current_user), @current_user\name_for_display!
          a class: "header_button", href: @url_for("user_settings"), "Settings"
          a class: "header_button", href: @url_for("user_logout"), "Log out"
        else
          a class: "header_button", href: @url_for("user_login"), "Log in"
          a class: "header_button", href: @url_for("user_register"), "Register"

  footer: =>
    div class: "footer", ->
      div class: "inner_column", ->
        div class: "footer_right", ->
          text "streak.club is "
          a href: "https://github.com/leafo/streak.club", "open source"
          raw " &middot; "
          revision = require "revision"
          a href: "https://github.com/leafo/streak.club/commit/#{revision}", rel: "nofollow", revision
          raw " &middot; "
          text "follow "
          a href: "https://twitter.com/thestreakclub", "@thestreakclub"

        raw "&copy; #{os.date "%Y", ngx.time!} &middot; moon coop &middot; "


        a href: @url_for"terms", "terms"
        -- raw " &middot; "
        -- a href: @url_for"privacy_policy", "privacy policy"
        -- raw " &middot; "
        -- a href: @url_for"support", "support/contact"

        if @current_user
          raw " &middot; "
          a href: @url_for"index", "home"

  main: =>
    @content_for "inner"

  all_js: =>
    @include_js "lib.js"
    @include_js "main.js"
    @content_for "all_js"

    script type: "text/javascript", ->
      opts = { flash: @flash }
      raw "new S.Header('#global_header', #{to_json opts});"
      raw "S.current_user = #{to_json @current_user.id};" if @current_user
      @content_for "js_init"

  include_fonts: =>
    if config._name == "production"
      link href: "http://fonts.googleapis.com/css?family=Dosis:300,400,700", rel: "stylesheet", type: "text/css"

    link href: @asset_url("fonts/streakclub/style.css"), rel: "stylesheet", type: "text/css"

  body_attributes: (class_name) =>
    {
      "data-page_name": @route_name
      class: class_name
    }

  content: =>
    html_5 ->
      head ->
        @head!
        @include_css "main.css"
        @google_analytics!

      body @body_attributes(@body_class), ->
        @header!
        @main!
        @footer!
        @all_js!

  google_analytics: =>
    script type: "text/javascript", ->
      raw "if (!window.location.hostname.match(/localhost/)) {"
      raw [[
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', 'UA-136625-12', 'auto');
        ga('send', 'pageview');
      ]]
      raw "}"
