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

  context 'enqueue FeedDeactivationWorker' do
    before(:each) do
      @feed = create(:feed)
      @feed_version1 = create(:feed_version, feed: @feed)
      @feed_version2 = create(:feed_version, feed: @feed)
    end

    it 'enqueues FeedDeactivationWorker if new active_feed_version' do
      @feed.activate_feed_version(@feed_version1.sha1, 1)
      expect {
        FeedActivationWorker.new.perform(@feed.onestop_id, @feed_version2.sha1, 1)
      }.to change(FeedDeactivationWorker.jobs, :count).by(1)
    end

    it 'does not enqueue FeedDeactivationWorker if same active_feed_version' do
      @feed.activate_feed_version(@feed_version2.sha1, 1)
      expect {
        FeedActivationWorker.new.perform(@feed.onestop_id, @feed_version2.sha1, 1)
      }.to change(FeedDeactivationWorker.jobs, :count).by(0)
    end

    it 'does not enqueue FeedDeactivationWorker if no previous active_feed_version' do
      expect {
        FeedActivationWorker.new.perform(@feed.onestop_id, @feed_version2.sha1, 1)
      }.to change(FeedDeactivationWorker.jobs, :count).by(0)
    end

  end
end
