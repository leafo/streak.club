import Flow from require "lapis.flow"

import preload from require "lapis.db.model"

import to_json_array from require "helpers.shapes"
import db_json from require "helpers.model"

class ReferenceSessionFlow extends Flow
  set_data: (state) =>
    @reference_session\update {
      data: db_json state
    }

  to_state: =>
    assert @reference_session, "missing reference session"

    participants = @reference_session\get_active_participants_paginated {
      per_page: 20
      prepare_results: (participants) ->
        preload participants, "user"
        participants
    }

    {
      uid: @reference_session.uid
      is_owner: @current_user and @current_user.id == @reference_session.user_id
      data: @reference_session.data

      participants: to_json_array\transform for p in participants\each_item!
        user = p\get_user!
        {
          id: user.id
          last_seen_at: p.last_seen_at
          name: user\name_for_display!
          url: @url_for user
          avatar_url: user\gravatar 80
        }

    }
