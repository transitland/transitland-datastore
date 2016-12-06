class EntitySerializer < ApplicationSerializer
  attributes :identifiers,
             :imported_from_feeds,
             :imported_from_feed_onestop_ids,
             :imported_from_feed_version_sha1s

  def imported_from_feeds
    object.imported_from_feeds.map { |eiff| {feed_onestop_id: eiff.feed.onestop_id, feed_version_sha1: eiff.feed_version.sha1, gtfs_id: eiff.gtfs_id} }
  end

  def imported_from_feed_onestop_ids
    object.imported_from_feeds.map(&:onestop_id).uniq
  end

  def imported_from_feed_version_sha1s
    object.imported_from_feed_versions.map(&:sha1).uniq
  end
end
