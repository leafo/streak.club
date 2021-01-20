


import OrderedPaginator from require "lapis.db.pagination"
import Uploads from require "models"


pager = OrderedPaginator Uploads, "id", "
  where type = ? and storage_type = ? and width is null and not deleted and ready
", Uploads.types.image, Uploads.storage_types.google_cloud_storage, {
  per_page: 1000
  order: "asc"
}

count = 0

imagesize = require "imagesize"

for upload in pager\each_item!
  count += 1
  print upload.id, upload.size, upload.filename, upload.extension

  -- try to read less than the full size of the image
  for size in *{
    1024
    1024*10
    1024*100
    false
  }
    if size and size >= upload.size
      size = false

    content, headers = upload\get_file_contents {
      headers: if size then { Range: "bytes=0-#{size}" }
    }

    break unless content

    image_type, data = imagesize.detect_image_from_bytes content

    unless image_type
      if size
        continue
      else
        print "!!!!", "Failed to detect image"
        upload\update_data {
          error: "imagesize failed to detect image"
        }
        break


    require("moon").p {
      bytes_needed: size or "all"
      :image_type
      :data
    }

    import to_json from require "lapis.util"

    imagesize_result = {k,v for k,v in pairs data}
    imagesize_result.type = image_type

    upload\update_data imagesize_result

    upload\update {
      width: data.width
      height: data.height
    }


    break

print "total:", count
