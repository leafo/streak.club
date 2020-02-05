html_builder = {
  "text"
  "raw"
  "widget"
  "element"
  "html_5"
  "capture"

  'area'
  "applet"
  'base'
  'br'
  'nobr'
  'col'
  'embed'
  'frame'
  'hr'
  'img'
  'input'
  'link'
  'meta'
  'param'

  'a'
  'abbr'
  'acronym'
  'address'
  'article'
  'aside'
  'audio'

  'b'
  'bdo'
  'big'
  'blockquote'
  'body'
  'button'

  'canvas'
  'caption'
  'center'
  'cite'
  'code'
  'colgroup'
  'command'

  'datalist'
  'dd'
  'del'
  'details'
  'dfn'
  'dialog'
  'div'
  'dl'
  'dt'

  'em'

  'fieldset'
  'figure'
  'footer'
  'form'
  'frameset'

  'h1'
  'h2'
  'h3'
  'h4'
  'h5'
  'h6'
  'head'
  'header'
  'hgroup'
  'html'
  'i'

  'iframe'
  'ins'
  'keygen'
  'kbd'
  'label'
  'legend'
  'li'

  'map'
  'mark'
  'meter'

  'nav'
  'noframes'
  'noscript'

  'object'
  'ol'
  'optgroup'
  'option'

  'p'
  'pre'
  'progress'

  'q'
  'ruby'
  'rt'
  'rp'
  's'

  'samp'
  'script'
  'section'
  'select'
  'small'
  'source'
  'span'
  'strike'

  'strong'
  'style'
  'sub'
  'sup'

  'table'
  'tbody'
  'td'
  'textarea'
  'tfoot'

  'th'
  'thead'
  'time'
  'title'
  'tr'
  'tt'

  'u'
  'ul'

  'var'
  'video'

  "svg"
  "summary"
}

{
  whitelist_globals: {
    ["."]: { "ngx" }

    ["spec/"]: {
      "it", "describe", "before_each", "after_each", "setup", "teardown", "pending"
    }

    ["views/"]: html_builder
    ["widgets/"]: html_builder
    ["emails/"]: html_builder
  }
}


