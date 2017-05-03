class ChangesetApplyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high,
                  retry: false,
                  unique: :until_and_while_executing,
                  unique_job_expiration: 60 * 60 * 22, # 22 hours
                  log_duplicate_payload: true

  def perform(changeset_id, cachekey)
    log "ChangesetApplyWorker: #{changeset_id}"
    # Processing
    errors = []
    warnings = []
    response = {}
    response[:status] = 'processing'
    Rails.cache.write(cachekey, response, expires_in: 1.day)
    # Apply
    changeset = Changeset.find(changeset_id)
    begin
      changeset.apply!
    rescue StandardError => error
      errors << {
        exception: 'ChangesetError',
        message: error.message
      }
    end
    # Update status
    response = {}
    response[:status] = errors.size > 0 ? 'error' : 'complete'
    response[:errors] = errors
    response[:warnings] = warnings
    Rails.cache.write(cachekey, response, expires_in: 1.day)
    response
  end
end
