module IsAnEntityImportedFromFeeds
  extend ActiveSupport::Concern

  included do
    has_many :entities_imported_from_feed, as: :entity
    has_many :imported_from_feeds, through: :entities_imported_from_feed, source: :feed
    has_many :imported_from_feed_versions, through: :entities_imported_from_feed, source: :feed_version
  end

  def imported_from_feed=(params)
    feed = params[:feed] || Feed.find_by!(onestop_id: params[:onestop_id])
    feed_version = params[:feed_version] || feed.feed_versions.find_by!(sha1: params[:sha1])
    self.entities_imported_from_feed.find_or_initialize_by(feed: feed, feed_version: feed_version)
  end
end
