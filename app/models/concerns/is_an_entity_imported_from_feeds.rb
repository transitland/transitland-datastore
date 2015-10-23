module IsAnEntityImportedFromFeeds
  extend ActiveSupport::Concern

  included do
    has_many :entities_imported_from_feed, as: :entity
    has_many :imported_from_feeds, through: :entities_imported_from_feed, source: :feed
    has_many :imported_from_feed_versions, through: :entities_imported_from_feed, source: :feed_version
  end

  def imported_from_feed=(imported_from_feed_params)
    imported_from_feed_params = HashHelpers::update_keys(imported_from_feed_params, :underscore)
    eiff_params = {}
    feed = Feed.find_by!(onestop_id: imported_from_feed_params[:onestop_id])
    eiff_params[:feed] = feed
    if imported_from_feed_params[:sha1].present?
      feed_version = feed.feed_versions.find_by!(sha1: imported_from_feed_params[:sha1])
      eiff_params[:feed_version] = feed_version
    end
    self.entities_imported_from_feed.find_or_initialize_by(eiff_params)
  end
end
