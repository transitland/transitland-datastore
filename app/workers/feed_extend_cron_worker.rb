class FeedExtendCronWorker
  include Sidekiq::Worker
  def perform
    if Figaro.env.extend_expired_feed_versions.presence == 'true'
      FeedMaintenanceService.extend_expired_feed_versions
    end
  end
end
