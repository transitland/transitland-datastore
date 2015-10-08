module IsAnEntityImportedFromFeeds
  extend ActiveSupport::Concern

  included do
    has_many :entities_imported_from_feed, as: :entity
    has_many :imported_from_feeds, through: :entities_imported_from_feed, source: :feed
  end

  def imported_from_feed_onestop_id=(value)
    feed = Feed.find_by!(onestop_id: value)
    self.imported_from_feeds << feed unless self.imported_from_feeds.exists?(feed.id)
  end

end
