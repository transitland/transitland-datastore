class FeedFetcherCronWorker
  include Sidekiq::Worker
  def perform
    FeedFetcherService.fetch_some_ready_feeds_async
  end
end
