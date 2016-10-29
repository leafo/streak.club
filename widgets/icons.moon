class Icons
  @icons: {
    bell: {
      width: 448
      height: 448
      path: [[<path fill="#000" d="M228 424c0-2.25-1.75-4-4-4-19.75 0-36-16.25-36-36 0-2.25-1.75-4-4-4s-4 1.75-4 4c0 24.25 19.75 44 44 44 2.25 0 4-1.75 4-4zM61.5 352h325c-44.75-50.5-66.5-119-66.5-208 0-32.25-30.5-80-96-80s-96 47.75-96 80c0 89-21.75 157.5-66.5 208zM432 352c0 17.5-14.5 32-32 32h-112c0 35.25-28.75 64-64 64s-64-28.75-64-64h-112c-17.5 0-32-14.5-32-32 37-31.25 80-87.25 80-208 0-48 39.75-100.5 106-110.25-1.25-3-2-6.25-2-9.75 0-13.25 10.75-24 24-24s24 10.75 24 24c0 3.5-0.75 6.75-2 9.75 66.25 9.75 106 62.25 106 110.25 0 120.75 43 176.75 80 208z"></path>]]
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

    if opts
      for k,v in pairs opts
        svg_opts[k] = v

    svg svg_opts, -> raw icon.path

-- vim: set nowrap:
