class EntitySerializer < ApplicationSerializer
  attributes :identifiers,
             :imported_from_feed_onestop_ids

  def imported_from_feed_onestop_ids
    object.feeds.map(&:onestop_id)
  end
end
