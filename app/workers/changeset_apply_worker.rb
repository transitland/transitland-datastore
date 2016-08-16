class ChangesetApplyWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing,
                  unique_job_expiration: 60 * 60, # 1 hour
                  log_duplicate_payload: true,
                  queue: :feed_eater,
                  retry: false

  def perform(changeset_id)
    logger.info "ChangesetApplyWorker: #{changeset_id}"
    changeset = Changeset.find(changeset_id)
    changeset.apply!
  end
end
