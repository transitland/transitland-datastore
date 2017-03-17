class FeedVersionInfoSerializer < ApplicationSerializer
  attributes :id,
             :statistics,
             :scheduled_service,
             :filenames,
             :feed_onestop_id,
             :feed_version_sha1,
             :created_at,
             :updated_at

  def feed_onestop_id
    object.feed.onestop_id
  end

  def feed_version_sha1
    object.feed_version.sha1
  end
end
