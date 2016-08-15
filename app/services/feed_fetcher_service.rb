class FeedFetcherService
  include Singleton

  REFETCH_WAIT = 24.hours
  SPLIT_REFETCH_INTO_GROUPS = 48 # and only refetch the first group

  def self.fetch_this_feed_now(feed)
    sync_fetch_and_return_feed_versions([feed])
  end

  def self.fetch_these_feeds_now(feeds)
    sync_fetch_and_return_feed_versions(feeds)
  end

  def self.fetch_this_feed_async(feed)
    async_enqueue_and_return_workers([feed])
  end

  def self.fetch_these_feeds_async(feeds)
    async_enqueue_and_return_workers(feeds)
  end

  def self.fetch_all_feeds_async
    feeds = Feed.where('')
    async_enqueue_and_return_workers(feeds)
  end

  def self.fetch_some_ready_feeds_async(since: REFETCH_WAIT.ago, split: SPLIT_REFETCH_INTO_GROUPS)
    feed_groups = Feed.where{
      (last_fetched_at == nil) | (last_fetched_at <= since)
    }.order(last_fetched_at: :asc).in_groups(split)
    async_enqueue_and_return_workers(feed_groups.first) # only the first group
  end

  private

    def self.sync_fetch_and_return_feed_versions(feeds)
      feeds.map do |feed|
        feed.fetch_and_return_feed_version
      end
    end

    def self.async_enqueue_and_return_workers(feeds)
      feeds.map do |feed|
        FeedFetcherWorker.perform_async(feed.onestop_id)
      end
    end

end
