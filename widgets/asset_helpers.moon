config = require("lapis.config").get!

cache_buster = require "cache_buster"

class AssetsHelpers
  asset_url: (src, opts) =>
    unless opts and opts.cache_buster == false
      src = "#{src}?#{cache_buster}"

    "/static/" .. src

  include_js: (...) =>
    script type: "text/javascript", src: @asset_url ...

  include_css: (...) =>
    link rel: "stylesheet", href: @asset_url ...

  include_jquery_ui: =>
    @include_js "lib/jquery-ui/js/jquery-ui.js"
    @include_css "lib/jquery-ui/css/jquery-ui.css"
    @include_css "lib/jquery-ui/css/jquery-ui.structure.css"
    @include_css "lib/jquery-ui/css/jquery-ui.theme.css"
