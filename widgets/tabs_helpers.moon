
-- set @page_name to automatically toggle tab
class TabsHelper
  page_tab: (label, name, url, sub) =>
    classes = "tab"
    if name == @page_name
      classes ..= " active"

    if sub
      classes ..= " has_sub"

    a href: url, class: classes, label
    if sub
      text " "
      span class: "tab_sub", sub

