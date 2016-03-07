describe FeedActivationWorker do
  it 'activates a feed' do
    feed = create(:feed)
    feed_version = create(:feed_version, feed: feed)
    expect(feed.active_feed_version).to be nil
    Sidekiq::Testing.inline! do
      FeedActivationWorker.perform_async(feed.onestop_id, feed_version.sha1, 2)
    end
    expect(feed.reload.active_feed_version).to eq(feed_version)
  end
end
