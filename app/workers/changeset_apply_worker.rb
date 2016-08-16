class ChangesetApplyWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing,
                  unique_job_expiration: 60 * 60, # 1 hour
                  log_duplicate_payload: true,
                  queue: :feed_eater,
                  retry: false

  def perform(changeset_id, cachekey)
    logger.info "ChangesetApplyWorker: #{changeset_id}"
    changeset = Changeset.find(changeset_id)
    changeset.apply!

    errors = []
    warnings = []
    response = {}
    response[:status] = errors.size > 0 ? 'error' : 'complete'
    response[:errors] = errors
    response[:warnings] = warnings
    Rails.cache.write(cachekey, response, expires_in: 1.day)
    response
  end
end
