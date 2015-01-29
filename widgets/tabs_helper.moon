
-- set @page_name to automatically toggle tab
class TabsHelper
  page_tab: (label, name, url) =>
    classes = "tab"
    if name == @page_name
      classes ..= " active"

    a href: url, class: classes, label
