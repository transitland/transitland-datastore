class EntitySerializer < ApplicationSerializer
  attribute :imported_from_feeds, if: :embed_imported_from_feeds?
  attribute :id, if: :include_id?
  attribute :geometry, if: :include_geometry?
  attributes :onestop_id, :created_at, :updated_at, :tags, :geometry

  has_many :issues, if: :embed_issues?

  def imported_from_feeds
    object.entities_imported_from_feed.map { |eiff| { feed_onestop_id: eiff.feed.try(:onestop_id), feed_version_sha1: eiff.feed_version.try(:sha1), gtfs_id: eiff.gtfs_id} }
  end

  def embed_imported_from_feeds?
    !!scope && !!scope[:embed_imported_from_feeds]
  end

  def embed_issues?
    !!scope && !!scope[:embed_issues]
  end

  def include_geometry?
    # support exclude_geometry here, but include_geometry takes priority
    if (scope.present? && scope.has_key?(:include_geometry) && !scope[:include_geometry].nil?)
      return scope[:include_geometry] && !!object.try(:geometry)
    elsif (scope.present? && scope.has_key?(:exclude_geometry) && !scope[:exclude_geometry].nil?)
      return !scope[:exclude_geometry] && !!object.try(:geometry)
    end
    return true
  end

  def include_id?
    !!scope && !!scope[:include_id]
  end
end
