class EntitySerializer < ApplicationSerializer
  attributes :imported_from_feeds

  has_many :issues, if: :has_issues

  def has_issues
    !!scope && !!scope[:embed_issues]
  end

  def imported_from_feeds
    object.entities_imported_from_feed.map { |eiff| { feed_onestop_id: eiff.feed.try(:onestop_id), feed_version_sha1: eiff.feed_version.try(:sha1), gtfs_id: eiff.gtfs_id} }
  end
end
