
import Flow from require "lapis.flow"
import preload from require "lapis.db.model"

class DashboardFlow extends Flow
  expose_assigns: true

  render: =>
    @created_streaks = @current_user\find_hosted_streaks!\get_page!
    @active_streaks = @current_user\find_participating_streaks(state: "active")\get_page!
    @completed_streaks = @current_user\find_participating_streaks(state: "completed")\get_page!
    @unseen_feed_count = @current_user\unseen_feed_count!

    unless next @active_streaks
      @featured_streaks = @find_featured_streaks!

    render: "dashboard"


  find_featured_streaks: =>
    import Streaks from require "models"
    streaks = Streaks\select "
      where id in (select streak_id from featured_streaks)
      and not deleted and publish_status = ?
      and membership_type = ?
      and (end_date is null or now() at time zone 'utc' < end_date)
      limit 20
    ", Streaks.publish_statuses.published, Streaks.membership_types.public

    preload streaks, "user"
    streaks = for streak in *streaks
      continue unless streak\allowed_to_view @current_user
      streak

    streaks


