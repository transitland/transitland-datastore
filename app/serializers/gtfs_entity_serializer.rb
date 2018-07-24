class GTFSEntitySerializer < ApplicationSerializer
    attribute :imported_from_feeds, if: :embed_imported_from_feeds?
    attribute :id
    attribute :geometry, if: :include_geometry?
    attribute :created_at
    attribute :updated_at
    # attribute :entity_onestop_id

    def entity_onestop_id
        object.entity.try(:onestop_id)
    end

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
        return unless object.has_attribute?(:geometry)
        if scope.present? && scope.has_key?(:geometry)
            return scope[:geometry]
        else
            return true
        end
    end
end
  