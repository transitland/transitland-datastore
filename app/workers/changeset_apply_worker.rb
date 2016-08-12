class ChangesetApplyWorker
  include Sidekiq::Worker

  def perform(changeset_id)
    logger.info "ChangesetApplyWorker: #{changeset_id}"
    changeset = Changeset.find(changeset_id)
    changeset.apply!
  end
end
