class TwitterCardHelpers
  twitter_card_thumb_size: "300x300#"
  twitter_card_default_description: "Streak Club is a place for staying motiviated by doing something creative every day or week"

  twitter_card_for_submission: (submission) =>
    uploads = submission\get_uploads!
    first_image = nil

    for u in *uploads
      if u\is_image!
        first_image = u
        break


    user = submission\get_user!
    profile = user\get_user_profile!

    meta name: "twitter:card", content: "summary_large_image"
    meta name: "twitter:site", content: "@itch.io"

    if twitter = profile\twitter_handle!
      meta name: "twitter:creator", content: "@#{twitter}"

    meta name: "twitter:title", content: submission\meta_title!
    meta name: "twitter:description", content: @twitter_card_default_description

    if first_image
      meta {
        name: "twitter:image"
        content: @build_url @url_for first_image, @twitter_card_thumb_size
      }

