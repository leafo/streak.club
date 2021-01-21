
import OrderedPaginator from require "lapis.db.pagination"
import Uploads from require "models"


pager = OrderedPaginator Uploads, "id", "where storage_type = ? and ready and not deleted", Uploads.storage_types.filesystem, {
  per_page: 100
}

count = 0

bucket = require("lapis.config").get!.storage_bucket
storage = require "secret.storage"


for upload in pager\each_item!
  count += 1
  bucket_key = "user_content/#{upload\path!}"
  print "Will upload to:", bucket, bucket_key

  content = upload\get_file_contents!

  print "File size:", #content

  upload_opts = {
    mimetype: Uploads.content_types[upload.extension]
    acl: "project-private"
  }

  require("moon").p upload_opts

  status = storage\put_file_string bucket, bucket_key, content, upload_opts

  if status == 200
    -- mark it as cloud storage
    upload\update {
      storage_type: Uploads.storage_types.google_cloud_storage
    }

    upload\update_data {
      migrated_from_filesystem: true
    }

print "total:", count

