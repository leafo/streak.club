config = require("lapis.config").get!

class AssetsHelpers
  asset_url: (src, opts) =>
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

  include_redactor: =>
    return unless config.enable_redactor
    @include_js "lib/redactor/redactor.js"
    @include_css "lib/redactor/redactor.css"

  include_textext: =>
    @include_js "lib/textext/js/textext.core.js"
    @include_js "lib/textext/js/textext.plugin.suggestions.js"
    @include_js "lib/textext/js/textext.plugin.autocomplete.js"
    @include_js "lib/textext/js/textext.plugin.tags.js"

    @include_css "lib/textext/css/textext.core.css"
    @include_css "lib/textext/css/textext.plugin.autocomplete.css"
    @include_css "lib/textext/css/textext.plugin.tags.css"

