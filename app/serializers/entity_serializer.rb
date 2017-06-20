class EntitySerializer < ApplicationSerializer
  attribute :imported_from_feeds, if: :embed_imported_from_feeds?
  attribute :id, if: :include_id?
  attribute :geometry, if: :include_geometry?
  attribute :onestop_id
  attribute :created_at
  attribute :updated_at
  attribute :tags
  has_many :issues, if: :embed_issues?

  def imported_from_feeds
    object.entities_imported_from_feed.map { |eiff| { feed_onestop_id: eiff.feed.try(:onestop_id), feed_version_sha1: eiff.feed_version.try(:sha1), gtfs_id: eiff.gtfs_id} }
  end

  def embed_imported_from_feeds?
    !!scope && !!scope[:imported_from_feeds]
  end

  def embed_issues?
    !!scope && !!scope[:issues]
  end

  def include_geometry?
    if scope.present? && scope.has_key?(:geometry)
      return scope[:geometry]
    else
      return true
    end
  end

  def include_id?
    !!scope && !!scope[:id]
  end
end
