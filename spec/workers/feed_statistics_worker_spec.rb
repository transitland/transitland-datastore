describe FeedStatisticsWorker do
  before(:each) {
  }

  context 'runs FeedStatisticsService' do
    it 'generates statistics' do
      feed_version = create(:feed_version_example)
      Sidekiq::Testing.inline! do
        FeedStatisticsWorker.perform_async(feed_version.sha1)
      end
    end
  end
end
