module IsAnEntityImportedFromFeeds
  extend ActiveSupport::Concern

  included do
    has_many :entities_imported_from_feed, as: :entity
    has_many :imported_from_feeds, through: :entities_imported_from_feed, source: :feed
    has_many :imported_from_feed_versions, through: :entities_imported_from_feed, source: :feed_version
  end

  def imported_from_feed=(imported_from_feed_params)
    params = HashHelpers::update_keys(imported_from_feed_params, :underscore)
    feed = params[:feed] || Feed.find_by!(onestop_id: params[:onestop_id])
    if params[:sha1].present?
      feed_version = params[:feed_version] || feed.feed_versions.find_by!(sha1: params[:sha1])
    end
    self.entities_imported_from_feed.find_or_initialize_by(feed: feed, feed_version: feed_version)
  end
end
