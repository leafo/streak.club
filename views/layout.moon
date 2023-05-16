import Widget from require "lapis.html"

import to_json from require "lapis.util"

config = require("lapis.config").get!

WelcomeBanner = require "widgets.welcome_banner"

class Layout extends require "widgets.base"
  @include "widgets.helpers"
  @include "widgets.table_helpers"
  @include "widgets.asset_helpers"
  @include "widgets.icons"

  @es_module: [[
    import {Header, Timezone} from "main/layout"
    import S from "main/state"

    new Header('#global_header', widget_params.header)

    if (widget_params.current_user_id) {
      S.current_user = widget_params.current_user_id
    }

    if (widget_params.timezone) {
      new Timezone(widget_params.timezone)
    }
  ]]

  widget_selector: =>
    [[document.body]]

  js_init: =>
    super {
      header: { flash: @flash }
      current_user_id: @current_user and @current_user.id
      timezone: if @current_user
        {
          tz_url: @url_for "set_timezone"
          last_timezone: @current_user.last_timezone
        }
    }

  head: =>
    meta charset: "UTF-8"
    meta name: "robots", content: "noindex" if @noindex

    link rel: "icon", type: "image/png", href: "/static/images/favicon.png"
    link rel: "manifest", href: @asset_url "manifest.json", cache_buster: false
    link rel: "apple-touch-icon", href: "/static/images/logo-144.png"
    meta name: "apple-mobile-web-app-title", content: "Streak Club"

    title ->
      if @title
        text "#{@title} - Streak Club"
      else
        text "Streak Club"

    meta name: "csrf_token", value: @csrf_token

    page_image = @build_url @meta_image or "/static/images/logo-banner.png"
    meta property: "og:site_name", content: "Streak Club"
    meta property: "og:image", content: page_image

    meta {
      property: "twitter:image"
      content: page_image
    }

    if @canonical_url
      link rel: "canonical", href: @canonical_url

    @content_for "meta_tags"

    if @embed_page
      base target: "_blank"

    if @meta_description
      meta property: "og:description", content: @meta_description
      meta name: "description", content: @meta_description

    if @view_widget and @view_widget.responsive
      meta name: "viewport", content: "width=device-width, initial-scale=1"

    @include_fonts!

  header: =>
    return if @embed_page

    div class: "header", id: "global_header", ->
      div class: "primary_header", ->
        a href: @url_for("index"), class: "logo", ->
          img class: "logo_image", width: 64, height: 40, src: "/static/images/rainbow-sm.png"
          span class: "logo_text", "Streak Club"


        form class: "header_search", action: @url_for("search"), ->
          input required: "required", type: "text", name: "q", placeholder: "Search...", value: @query

      div class: "right_header", ->
        if @current_user
          a class: "user_name", href: @url_for(@current_user), @current_user\name_for_display!

          available = 0
          for n in *@global_notifications
            available += 1 unless n.seen

          if available > 0
            a href: @url_for("notifications"), class: "notification_bubble", available
          else
            a {
              href: @url_for("notifications")
              class: "notifications_bell"
              title: "Notifications"
            }, ->
              @icon "bell", 18

          a class: "header_button #{@route_name == "index" and "current" or ""}", href: @url_for("index"), "Dashboard"
          div class: "menu_wrapper", ->
            button class: "menu_button", ->
              @icon "menu", 18

            div class: "menu_popup", ->
              a href: @url_for("new_streak"), "New streak"
              a href: @url_for("user_settings"), "Settings"
              a href: @url_for("user_logout"), "Log out"

              if @current_user\is_admin!
                a href: @url_for("admin.spam_queue"), ->
                  strong "Spam Queue"
        else
          a class: "header_button", href: @url_for("user_login"), "Log in"
          a class: "header_button", href: @url_for("user_register"), "Register"

  footer: =>
    div class: "footer", ->
      div class: "inner_footer", ->
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
        raw " &middot; "
        a href: @url_for"privacy_policy", "privacy policy"
        raw " &middot; "
        a href: "http://streakclub.tumblr.com", "blog"

        if @current_user
          raw " &middot; "
          a href: @url_for"index", "home"

  main: =>
    @content_for "inner"

  all_js: =>
    @include_js "lib.js"
    if config._name == "production"
      @include_js "main.min.js"
    else
      @include_js "main.js"

    -- NOTE: this is being used to include other dependencies on some pages
    @content_for "all_js"

    script type: "text/javascript", ->
      raw @js_init! -- initialize the layout
      @content_for "js_init"

  include_fonts: =>
    if config._name == "production"
      link href: "//fonts.googleapis.com/css?family=Dosis:300,400,700", rel: "stylesheet", type: "text/css"

  body_attributes: (...) =>
    {
      "data-page_name": @route_name
      class: {
        responsive: @view_widget and @view_widget.responsive
        embed_page: @embed_page
        logged_in: @current_user
        logged_out: not @current_user
        ...
      }
    }

  content: =>
    html_5 ->
      head ->
        @head!
        @include_css "main.css"
        @google_analytics!
        script id: "markdown_src", "data-src": @asset_url "lib.markdown.js"

      body @body_attributes(@body_class), ->
        @header!

        if @show_welcome_banner and not @current_user and not @embed_page
          widget WelcomeBanner

        @main!
        @footer!
        @all_js!
        @render_query_log!

  google_analytics: =>
    return unless config._name == "production"
    script type: "text/javascript", ->
      raw [[
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', 'UA-136625-12', 'auto');
        ga('send', 'pageview');
      ]]

    raw [[
      <script async src="https://www.googletagmanager.com/gtag/js?id=G-J983SZ6K5B"></script>
      <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());

        gtag('config', 'G-J983SZ6K5B');
      </script>
    ]]


  render_query_log: =>
    return unless @current_user and @current_user\is_admin!
    query_log = ngx and ngx.ctx and ngx.ctx.query_log

    return unless query_log

    details class: "query_log", ->
      summary ->
        text "Queries"
        text " "
        strong "(#{@format_number #query_log})"

      total_time = 0
      for {_, d} in *query_log
        total_time += d

      p ->
        text "Total query time: "
        code @format_duration total_time

      @column_table query_log, {
        {"query", type: "collapse_pre", value: (l) -> l[1]}
        {"duration", type: "duration", value: (l) -> l[2]}
      }
