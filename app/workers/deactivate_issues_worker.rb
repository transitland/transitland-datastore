class DeactivateIssuesWorker
  include Sidekiq::Worker

  def perform(cachekey)
    logger.info "DeactivateIssuesWorker: "
    # Processing
    errors = []
    response = {}
    response[:status] = 'processing'
    Rails.cache.write(cachekey, response, expires_in: 1.day)
    begin
      Issue.bulk_deactivate
    rescue StandardError => error
      errors << {
        exception: 'StandardError',
        message: error.message
      }
    end
    # Update status
    response = {}
    response[:status] = errors.size > 0 ? 'error' : 'complete'
    response[:errors] = errors
    response[:warnings] = []
    Rails.cache.write(cachekey, response, expires_in: 1.day)
    response
  end
end
