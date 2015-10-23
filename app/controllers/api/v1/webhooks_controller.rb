class Api::V1::WebhooksController < Api::V1::BaseApiController
  before_filter :require_api_auth_token

  def feed_fetcher
    workers = Feed.async_fetch_all_feeds
    if workers
      render json: {
        code: 200,
        message: "FeedFetcherWorkers #{workers.join(', ')} enqueued.",
        errors: []
      }
    else
      raise 'FeedFetcherWorkers could not be created or enqueued.'
    end
  end

  def feed_eater
    feed = Feed.find_by_onestop_id!(params[:feed_onestop_id])
    feed_version_sha1 = params[:feed_version_sha1]
    if feed_version_sha1.present?
      feed_version = feed.feed_versions.find_by(sha1: feed_version_sha1)
    else
      feed_version = feed.feed_versions.last! # TODO: decide on sort order of feed versions
    end
    import_level = params[:import_level].present? ? params[:import_level].to_i : 0
    feed_eater_worker = FeedEaterWorker.perform_async(feed.onestop_id, feed_version.sha1, import_level)
    if feed_eater_worker
      render json: {
        code: 200,
        message: "FeedEaterWorker ##{feed_eater_worker} has been enqueued.",
        errors: []
      }
    else
      raise 'FeedEaterWorker could not be created or enqueued.'
    end
  end
end
