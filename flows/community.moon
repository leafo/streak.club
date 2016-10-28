import Flow from require "lapis.flow"

import assert_error from require "lapis.application"

class CommunityFlow extends Flow
  show_category: =>
    assert @category, "missing category"

    assert_error @category\allowed_to_view @current_user

    BrowsingFlow = require "community.flows.browsing"
    @flow = BrowsingFlow(@)

    @flow\category_single!
    @children = @category\get_children!

    all_topics = {}
    browse_opts = {}

    @flow\category_topics browse_opts
    @flow\sticky_category_topics browse_opts

    for t in *@topics
      table.insert all_topics, t

    for t in *@sticky_topics
      table.insert all_topics, t

    true

  