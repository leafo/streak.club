return unless @React

{ div, span, a, p, ol, ul, li, strong, em, img,
  form, label, input, textarea, button,
  h1, h2, h3, h4, h5, h6, pre, code, select, option } = ReactDOMFactories

fragment = React.createFactory React.Fragment

# vim: set expandtab ts=2 sw=2 ft=coffee:
