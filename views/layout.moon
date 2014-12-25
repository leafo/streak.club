import Widget from require "lapis.html"

import to_json from require "lapis.util"

class Layout extends Widget
  head: =>
    meta charset: "UTF-8"
    meta name: "robots", content: "noindex" if @noindex

    -- TODO: this stuff
    -- raw [[<meta name="msvalidate.01" content="" />]]
    -- raw [[<meta property="fb:app_id" content="" />]]

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
    div class: "header", ->
      div class: "right_buttons", ->
        a class: "header_button", href: @url_for("user_login"), "Log in"
        a class: "header_button", href: @url_for("user_register"), "Register"

  footer: =>
  main: =>
    @content_for "inner"

  all_js: =>
    @include_js "lib.js"
    @include_js "main.js"

    script type: "text/javascript", ->
      @content_for "js_init"

  include_fonts: =>
    raw [[<link href='http://fonts.googleapis.com/css?family=Open+Sans:400italic,400,700' rel='stylesheet' type='text/css'>]]

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

        -- if @flash
        --   script type: "text/javascript", ->
        --     raw "S.flash(#{to_json @flash});"

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

  asset_url: (src, opts) =>
    "/static/" .. src

  include_js: (...) =>
    script type: "text/javascript", src: @asset_url ...

  include_css: (...) =>
    link rel: "stylesheet", href: @asset_url ...
