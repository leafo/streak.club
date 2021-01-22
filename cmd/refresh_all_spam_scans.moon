
db = require "lapis.db"
import OrderedPaginator from require "lapis.db.pagination"
import Users, SpamScans from require "models"

pager = OrderedPaginator Users, "id",
  "where not exists(select 1 from spam_scans where users.id = spam_scans.user_id and (train_status in ? or review_status = ?))",
  db.list { SpamScans.train_statuses.ham, SpamScans.train_statuses.spam },
  SpamScans.review_statuses.reviewed,
  {
    per_page: 1000
  }

count = 0

for user in pager\each_item!
  SpamScans\refresh_for_user user
  count += 1

print count

