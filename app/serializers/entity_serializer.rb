class EntitySerializer < ApplicationSerializer
  attributes :identifiers,
             :imported_from_feed_onestop_ids,
             :imported_from_feed_version_sha1s

  def imported_from_feed_onestop_ids
    object.imported_from_feeds.pluck(:onestop_id).uniq
  end

  def imported_from_feed_version_sha1s
    object.imported_from_feed_versions.pluck(:sha1).uniq
  end
end
