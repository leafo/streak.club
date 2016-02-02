
import Flow from require "lapis.flow"

class DashboardFlow extends Flow
  expose_assigns: true

  render: =>
    @created_streaks = @current_user\find_hosted_streaks!\get_page!
    @active_streaks = @current_user\find_participating_streaks(state: "active")\get_page!
    @completed_streaks = @current_user\find_participating_streaks(state: "completed")\get_page!
    @unseen_feed_count = @current_user\unseen_feed_count!
    render: "dashboard"

