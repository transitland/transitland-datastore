class EntitySerializer < ApplicationSerializer
  attributes :identifiers,
             :imported_from_feed_onestop_id

  def imported_from_feed_onestop_id
    object.feed.try(:onestop_id)
  end
end
