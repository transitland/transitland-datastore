describe FeedDeactivationWorker do
  it 'deactivates a feed' do
    feed = create(:feed)
    feed_version1 = create(:feed_version, feed: feed)
    ssp = create(:schedule_stop_pair, feed: feed, feed_version: feed_version1)
    feed_version2 = create(:feed_version, feed: feed)
    feed.activate_feed_version(feed_version2.sha1, 2)

    expect(feed_version1.imported_schedule_stop_pairs.count).to eq(1)
    Sidekiq::Testing.inline! do
      FeedDeactivationWorker.perform_async(feed.onestop_id, feed_version1.sha1)
    end
    expect(feed_version1.imported_schedule_stop_pairs.count).to eq(0)
  end
end
