
-- set @page_name to automatically toggle tab
class TabsHelper
  page_tab: (label, name, url, sub) =>
    classes = "tab"
    if name == @page_name
      classes ..= " active"

    if sub
      div class: "tab_wrapper", ->
        a href: url, class: classes, label
        text " "
        span class: "tab_sub", sub
    else
      a href: url, class: classes, label

