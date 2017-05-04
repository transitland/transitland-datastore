def load_feed(feed_version_name: nil, feed_version: nil, import_level: 1, block_before_level_1: nil, block_before_level_2: nil)
  feed_version = create(feed_version_name) if feed_version.nil?
  feed = feed_version.feed
  Sidekiq::Testing.inline! do
    FeedEaterService.import_level_1(
      feed.onestop_id,
      feed_version_sha1: feed_version.sha1,
      import_level: import_level,
      block_before_level_1: block_before_level_1,
      block_before_level_2: block_before_level_2
    )
  end
  return feed.reload, feed_version.reload
end
