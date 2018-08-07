class GTFSEntitySerializer < ApplicationSerializer
    attribute :feed_version, if: :embed_imported_from_feeds?
    attribute :feed, if: :embed_imported_from_feeds?
    attribute :id
    attribute :geometry, if: :include_geometry?
    attribute :created_at
    attribute :updated_at
    # attribute :entity_onestop_id

    def entity_onestop_id
        object.entity.try(:onestop_id)
    end

    def feed
        object.feed.onestop_id
    end

    def feed_version
        object.feed_version.sha1
    end
    
    def embed_imported_from_feeds?
        !!scope && !!scope[:imported_from_feeds]
    end

    def embed_issues?
        !!scope && !!scope[:issues]
    end

    def include_geometry?
        return unless object.respond_to?(:geometry)
        if scope.present? && scope.has_key?(:geometry)
            return scope[:geometry]
        else
            return true
        end
    end
end
  