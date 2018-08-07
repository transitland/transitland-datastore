module GTFSEntity
    extend ActiveSupport::Concern
    included do
        belongs_to :feed_version
        has_one :feed, through: :feed_version, source_type: 'Feed'
        attr_accessor(:skip_association_validations)

        scope :where_import_level, -> (import_level) {
            joins(:entities_imported_from_feed)
              .where(entities_imported_from_feed: {
                feed_version_id: FeedVersion.where(import_level: import_level).ids
              })
              .distinct
          }
      
          scope :where_imported_from_feed, -> (feeds) {
            joins(:feed_version).where(feed_version: {feed_id: Array.wrap(feeds).map { |i| i.try(:id) || i }})  
          }
      
          scope :where_imported_from_feed_version, -> (feed_versions) {
            where(feed_version: Array.wrap(feed_versions).map { |i| i.try(:id) })
          }
      
          scope :where_imported_from_active_feed_version, -> {
            joins('INNER JOIN current_feeds ON feed_version_id = current_feeds.active_feed_version_id')
          }
          
          scope :where_not_imported_from_active_feed_version, -> {
            joins('INNER JOIN current_feeds ON feed_version_id != current_feeds.active_feed_version_id')
          }
    end
  end
  