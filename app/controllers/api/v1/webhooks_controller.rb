class Api::V1::WebhooksController < Api::V1::BaseApiController
  before_filter :require_api_auth_token

  def feed_eater
    feed_onestop_ids = params[:feed_onestop_ids].try(:split, ',') || []
    feed_eater_worker = FeedEaterWorker.perform_async(feed_onestop_ids)
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
