module IsAnEntityImportedFromFeeds
  extend ActiveSupport::Concern
  included do
    has_many :entities_imported_from_feed, as: :entity
    has_many :imported_from_feeds, through: :entities_imported_from_feed, source: :feed
    has_many :imported_from_feed_versions, through: :entities_imported_from_feed, source: :feed_version
    scope :where_import_level, -> (import_level) {
      joins(:entities_imported_from_feed)
        .where(entities_imported_from_feed: {
          feed_version_id: FeedVersion.where(import_level: import_level).ids
        })
        .distinct
    }
    scope :where_imported_from_feed, -> (feed) {
      joins(:entities_imported_from_feed)
        .where(entities_imported_from_feed: {
          feed_id: feed.id
        })
        .distinct
    }
    scope :where_imported_from_feed_version, -> (feed_version) {
      joins(:entities_imported_from_feed)
        .where(entities_imported_from_feed: {
          feed_version_id: feed_version.id
        })
        .distinct
    }

    scope :where_inactive, -> {
      active_feed_version_ids = FeedVersion.where_active.select(:id).distinct.pluck(:id)
      referenced_ids = EntityImportedFromFeed.where(entity_type: self, feed_version_id: active_feed_version_ids).select(:entity_id).distinct.pluck(:entity_id)
      all_ids = self.select(:id).pluck(:id)
      where(id: (all_ids - referenced_ids))
    }

  end
end
