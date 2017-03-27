class Api::V1::WebhooksController < Api::V1::BaseApiController
  before_filter :require_api_auth_token

  # POST /webhooks/feed_fetcher
  include Swagger::Blocks
  swagger_path '/webhooks/feed_fetcher' do
    operation :get do
      key :tags, ['admin']
      key :name, :tags
      key :summary, 'Trigger a feed to be fetched'
      key :description, 'Requires API authentication.'
      key :produces, ['application/json']
      parameter do
        key :name, :onestop_id
        key :in, :query
        key :description, 'Onestop ID for feed. If none is specified, all feeds will be fetched.'
        key :required, false
        key :type, :string
      end
      response 200 do
        # key :description, 'stop response'
        # schema do
          # key :'$ref', :Stop
        # end
      end
    end
  end
  def feed_fetcher
    if params[:feed_onestop_id].present?
      feed_onestop_ids = params[:feed_onestop_id].split(',')
      feeds = Feed.find_by_onestop_ids!(feed_onestop_ids)
    else
      feeds = Feed.where('')
    end
    workers = FeedFetcherService.fetch_these_feeds_async(feeds)
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

  # POST /webhooks/feed_eater
  include Swagger::Blocks
  swagger_path '/webhooks/feed_eater' do
    operation :get do
      key :tags, ['admin']
      key :name, :tags
      key :summary, 'Trigger a feed to be imported (through the FeedEater pipeline)'
      key :description, 'Requires API authentication.'
      key :produces, ['application/json']
      parameter do
        key :name, :onestop_id
        key :in, :query
        key :description, 'Onestop ID for feed'
        key :required, true
        key :type, :string
      end
      parameter do
        key :name, :sha1
        key :in, :query
        key :description, 'SHA1 hash for feed version. If none specified, the most recent feed version is imported.'
        key :required, false
        key :type, :string
      end
      response 200 do
        # key :description, 'stop response'
        # schema do
          # key :'$ref', :Stop
        # end
      end
    end
  end
  def feed_eater
    feed = Feed.find_by_onestop_id!(params[:feed_onestop_id])
    feed_version_sha1 = params[:feed_version_sha1]
    if feed_version_sha1.present?
      feed_version = feed.feed_versions.find_by(sha1: feed_version_sha1)
    else
      feed_version = feed.feed_versions.first!
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
