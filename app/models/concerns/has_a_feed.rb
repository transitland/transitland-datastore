module HasAFeed
  extend ActiveSupport::Concern

  included do
    has_many :entities_imported_from_feed, as: :entity
    has_many :feeds, through: :entities_imported_from_feed
  end
  
  def imported_from_feed_onestop_id=(value)
    feed = Feed.find_by!(onestop_id: value)
    self.feeds << feed unless self.feeds.exists?(feed.id)
  end
  
end
