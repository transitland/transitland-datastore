class FeedEnqueueCronWorker
  include Sidekiq::Worker
  def perform
    date = DateTime.now
    max_imports = (Figaro.env.enqueue_next_feed_versions_max.presence || 0).to_i
    if max_imports > 0
      FeedMaintenanceService.enqueue_next_feed_versions(date, max_imports: max_imports)
    end
  end
end
