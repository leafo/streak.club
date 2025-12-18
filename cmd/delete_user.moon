-- Delete a user account and all associated data

argparse = require "argparse"
colors = require "ansicolors"
db = require "lapis.db"
config = require("lapis.config").get!

import
  Users
  Submissions
  SubmissionLikes
  SubmissionComments
  SubmissionTags
  StreakSubmissions
  Streaks
  StreakUsers
  StreakUserNotificationSettings
  Uploads
  UploadThumbnails
  Followings
  Notifications
  NotificationObjects
  ApiKeys
  UserProfiles
  SpamScans
  RegisterReferrers
  RecaptchaResults
  from require "models"

parser = argparse "delete_user.moon", "Delete a user account and all associated data"

parser\argument("user_id", "User ID to delete")\convert tonumber
parser\flag "--dry-run", "Run in transaction and rollback (no actual deletion)"

args = parser\parse [v for _, v in ipairs _G.arg]

dry_run = args.dry_run

-- Find user
user = Users\find args.user_id

unless user
  print colors "%{red}User not found: #{args.user_id}"
  os.exit 1

print colors "Found user: %{cyan}#{user.username}%{reset} (id: #{user.id})"
print ""

if dry_run
  print colors "%{yellow}=== DRY RUN MODE - Will rollback at end ==="
  print ""

-- Track deletion counts
counts = {}
delete_count = (name, n) ->
  counts[name] = (counts[name] or 0) + n
  if n > 0
    print "  Deleted #{n} #{name}"

-- Collect uploads for file deletion (only if not dry-run)
uploads_to_delete = {}

-- Start transaction
db.query "begin"

user_id = user.id

-- 1. Get all submission IDs for this user
submission_ids = db.query "select id from submissions where user_id = ?", user_id
submission_ids = [s.id for s in *submission_ids]

print "User has #{#submission_ids} submissions"

if #submission_ids > 0
  submission_ids_str = table.concat submission_ids, ","

  -- 2. Delete likes ON user's submissions
  res = db.delete "submission_likes", db.interpolate_query [[
    submission_id in (?)
  ]], db.list submission_ids
  delete_count "submission_likes (on submissions)", res.affected_rows

  -- 3. Delete comments ON user's submissions
  res = db.delete "submission_comments", db.interpolate_query [[
    submission_id in (?)
  ]], db.list submission_ids
  delete_count "submission_comments (on submissions)", res.affected_rows

  -- 4. Delete submission tags
  res = db.delete "submission_tags", db.interpolate_query [[
    submission_id in (?)
  ]], db.list submission_ids
  delete_count "submission_tags", res.affected_rows

  -- 5. Update streak submission counts before deleting streak_submissions
  db.query [[
    update streaks set submissions_count = submissions_count - counts.cnt
    from (
      select streak_id, count(*) as cnt
      from streak_submissions
      where submission_id in (]] .. submission_ids_str .. [[)
      group by streak_id
    ) as counts
    where streaks.id = counts.streak_id
  ]]

  -- 6. Delete streak_submissions for user's submissions
  res = db.delete "streak_submissions", db.interpolate_query [[
    submission_id in (?)
  ]], db.list submission_ids
  delete_count "streak_submissions (for submissions)", res.affected_rows

  -- 7. Collect and delete uploads
  uploads = Uploads\select [[
    where object_type = ? and object_id in (]] .. submission_ids_str .. [[)
  ]], Uploads.object_types.submission

  for upload in *uploads
    table.insert uploads_to_delete, upload

  -- Delete upload thumbnails first
  if #uploads > 0
    upload_ids = [u.id for u in *uploads]
    res = db.delete "upload_thumbnails", db.interpolate_query [[
      upload_id in (?)
    ]], db.list upload_ids
    delete_count "upload_thumbnails", res.affected_rows

  res = db.delete "uploads", db.interpolate_query [[
    object_type = ? and object_id in (?)
  ]], Uploads.object_types.submission, db.list submission_ids
  delete_count "uploads", res.affected_rows

  -- 8. Delete submissions
  res = db.delete "submissions", db.interpolate_query [[
    id in (?)
  ]], db.list submission_ids
  delete_count "submissions", res.affected_rows

-- 9. Delete likes BY this user (and update counts on those submissions)
db.query [[
  update submissions set likes_count = likes_count - 1
  where id in (select submission_id from submission_likes where user_id = ?)
]], user_id
res = db.delete "submission_likes", user_id: user_id
delete_count "submission_likes (by user)", res.affected_rows

-- 10. Delete comments BY this user (and update counts)
db.query [[
  update submissions set comments_count = comments_count - 1
  where id in (select submission_id from submission_comments where user_id = ? and not deleted)
]], user_id
res = db.delete "submission_comments", user_id: user_id
delete_count "submission_comments (by user)", res.affected_rows

-- 11. Delete submission tags by user (on others' submissions)
res = db.delete "submission_tags", user_id: user_id
delete_count "submission_tags (by user)", res.affected_rows

-- 12. Update streak user counts before deleting streak_users
db.query [[
  update streaks set users_count = users_count - 1
  where id in (select streak_id from streak_users where user_id = ? and not pending)
]], user_id
db.query [[
  update streaks set pending_users_count = pending_users_count - 1
  where id in (select streak_id from streak_users where user_id = ? and pending)
]], user_id

-- 13. Delete streak user notification settings
res = db.delete "streak_user_notification_settings", user_id: user_id
delete_count "streak_user_notification_settings", res.affected_rows

-- 14. Delete streak_users (user's participation in streaks)
res = db.delete "streak_users", user_id: user_id
delete_count "streak_users", res.affected_rows

-- 15. Handle streaks owned by user
owned_streaks = Streaks\select "where user_id = ?", user_id
print "User owns #{#owned_streaks} streaks"

for streak in *owned_streaks
  print "  Deleting streak: #{streak.title} (id: #{streak.id})"

  -- Delete all streak_user_notification_settings for this streak
  res = db.delete "streak_user_notification_settings", streak_id: streak.id
  delete_count "streak_user_notification_settings (owned)", res.affected_rows

  -- Delete all streak_users for this streak
  res = db.delete "streak_users", streak_id: streak.id
  delete_count "streak_users (owned)", res.affected_rows

  -- Delete all streak_submissions for this streak
  res = db.delete "streak_submissions", streak_id: streak.id
  delete_count "streak_submissions (owned)", res.affected_rows

-- Delete the streaks
res = db.delete "streaks", user_id: user_id
delete_count "streaks", res.affected_rows

-- 16. Update follower counts for users this user followed
db.query [[
  update users set followers_count = followers_count - 1
  where id in (select dest_user_id from followings where source_user_id = ?)
]], user_id

-- 17. Update following counts for users who followed this user
db.query [[
  update users set following_count = following_count - 1
  where id in (select source_user_id from followings where dest_user_id = ?)
]], user_id

-- 18. Delete followings (both directions)
res = db.delete "followings", source_user_id: user_id
delete_count "followings (by user)", res.affected_rows
res = db.delete "followings", dest_user_id: user_id
delete_count "followings (to user)", res.affected_rows

-- 19. Delete notification_objects (via subquery)
res = db.query [[
  delete from notification_objects
  where notification_id in (select id from notifications where user_id = ?)
]], user_id
delete_count "notification_objects", res.affected_rows

-- 20. Delete notifications
res = db.delete "notifications", user_id: user_id
delete_count "notifications", res.affected_rows

-- 21. Community tables
community_tables = {
  "community_votes"
  "community_subscriptions"
  "community_bookmarks"
  "community_topic_participants"
  "community_pending_posts"
  "community_post_edits"
  "community_post_reports"
  "community_moderators"
  "community_moderation_logs"
  "community_category_members"
  "community_activity_logs"
  "community_user_category_last_seens"
  "community_user_topic_last_seens"
  "community_posts"
}

for tbl in *community_tables
  res = db.delete tbl, user_id: user_id
  delete_count tbl, res.affected_rows

-- Community blocks (two columns)
db.delete "community_blocks", blocking_user_id: user_id
db.delete "community_blocks", blocked_user_id: user_id

-- Community bans (two columns)
db.delete "community_bans", banned_user_id: user_id
db.delete "community_bans", banning_user_id: user_id

-- Community users
db.delete "community_users", user_id: user_id

-- 22. Delete API keys
res = db.delete "api_keys", user_id: user_id
delete_count "api_keys", res.affected_rows

-- 23. Delete user IP addresses
res = db.delete "user_ip_addresses", user_id: user_id
delete_count "user_ip_addresses", res.affected_rows

-- 24. Delete spam scans
res = db.delete "spam_scans", user_id: user_id
delete_count "spam_scans", res.affected_rows

-- 25. Delete register referrers
res = db.delete "register_referrers", user_id: user_id
delete_count "register_referrers", res.affected_rows

-- 26. Delete recaptcha results
res = db.delete "recaptcha_results", {
  object_type: 1  -- user
  object_id: user_id
}
delete_count "recaptcha_results", res.affected_rows

-- 27. Delete user profile
res = db.delete "user_profiles", user_id: user_id
delete_count "user_profiles", res.affected_rows

-- 28. Delete the user
res = db.delete "users", id: user_id
delete_count "users", res.affected_rows

if dry_run
  db.query "rollback"
  print ""
  print colors "%{yellow}=== DRY RUN COMPLETE - Transaction rolled back ==="
  print "No data was actually deleted"

  if #uploads_to_delete > 0
    print ""
    print "Uploads that would be deleted (#{#uploads_to_delete}):"
    for upload in *uploads_to_delete
      print "  #{upload.id}: #{Uploads.types[upload.type]}/#{upload.filename}"
else
  db.query "commit"
  print ""
  print colors "%{green}=== Transaction committed ==="

  -- Delete files from storage
  if #uploads_to_delete > 0
    print ""
    print "Deleting #{#uploads_to_delete} upload files..."

    for upload in *uploads_to_delete
      continue unless upload.ready

      switch upload.storage_type
        when Uploads.storage_types.filesystem
          import shell_escape from require "lapis.cmd.path"
          path = "#{config.user_content_path}/uploads/#{Uploads.types[upload.type]}/#{upload.id}.#{upload.extension}"
          os.execute "rm -f '#{shell_escape path}'"
        when Uploads.storage_types.google_cloud_storage
          storage = require "secret.storage"
          bucket = config.storage_bucket
          key = "user_content/uploads/#{Uploads.types[upload.type]}/#{upload.id}.#{upload.extension}"
          storage\delete_file bucket, key

    print "File deletion complete"

-- Print summary
print ""
print colors "%{bright}=== Summary ==="
total = 0
for name, count in pairs counts
  total += count

print "Total records deleted: #{total}"
print colors "User %{cyan}#{user.username}%{reset} (id: #{user.id}) has been deleted"
