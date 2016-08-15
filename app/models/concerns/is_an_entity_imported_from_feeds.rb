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

    scope :where_active, -> {
      joins(:entities_imported_from_feed)
        .joins('INNER JOIN current_feeds ON entities_imported_from_feed.feed_version_id = current_feeds.active_feed_version_id')
        .distinct
    }

    scope :where_inactive, -> {
      # This may be possible with a complex outer join, but this will do.
      where(id: Stop.all.select(:id).pluck(:id) - Stop.where_active.select(:id).pluck(:id))
    }

  end
end
