class Icons
  @icons: {
    bell: {
      width: 448
      height: 448
      path: [[<path d="M228 424c0-2.25-1.75-4-4-4-19.75 0-36-16.25-36-36 0-2.25-1.75-4-4-4s-4 1.75-4 4c0 24.25 19.75 44 44 44 2.25 0 4-1.75 4-4zM61.5 352h325c-44.75-50.5-66.5-119-66.5-208 0-32.25-30.5-80-96-80s-96 47.75-96 80c0 89-21.75 157.5-66.5 208zM432 352c0 17.5-14.5 32-32 32h-112c0 35.25-28.75 64-64 64s-64-28.75-64-64h-112c-17.5 0-32-14.5-32-32 37-31.25 80-87.25 80-208 0-48 39.75-100.5 106-110.25-1.25-3-2-6.25-2-9.75 0-13.25 10.75-24 24-24s24 10.75 24 24c0 3.5-0.75 6.75-2 9.75 66.25 9.75 106 62.25 106 110.25 0 120.75 43 176.75 80 208z"></path>]]
    }

    menu: {
      width: 60
      height: 60
      path: [[<g><path d="M30,16c4.411,0,8-3.589,8-8s-3.589-8-8-8s-8,3.589-8,8S25.589,16,30,16z" /><path d="M30,44c-4.411,0-8,3.589-8,8s3.589,8,8,8s8-3.589,8-8S34.411,44,30,44z" /><path d="M30,22c-4.411,0-8,3.589-8,8s3.589,8,8,8s8-3.589,8-8S34.411,22,30,22z" /></g>]]
    }

    reply: {
      width: 24
      height: 24
      svg_opts: {
        "stroke-linecap": "round"
        "stroke-linejoin": "round"
        "stroke-width": "2"
        fill: "none"
        stroke: "currentColor"
      }
      path: [[<polyline points="15 10 20 15 15 20"></polyline><path d="M4 4v7a4 4 0 0 0 4 4h12"></path>]]
    }

    calendar: {
      width: 24
      height: 24
      svg_opts: {
        "stroke-linecap": "round"
        "stroke-linejoin": "round"
        "stroke-width": "2"
        fill: "none"
        stroke: "currentColor"
      }
      path: [[<rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line>]]
    }
  }

  icon: (name, width, opts) =>
    icon = assert Icons.icons[name]
    unless icon
      error "Failed to find icon: #{name}"

    width or= icon.width
    height = math.floor width / icon.width * icon.height

    svg_opts = {
      "aria-hidden": true
      class: "svgicon icon_#{name}"
      role: "img"
      version: "1.1"
      viewBox: "0 0 #{icon.width} #{icon.height}"
      :width, :height
    }

    if icon.svg_opts
      for k,v in pairs icon.svg_opts
        svg_opts[k] = v

    if opts
      for k,v in pairs opts
        svg_opts[k] = v

    svg svg_opts, -> raw icon.path

-- vim: set nowrap:
