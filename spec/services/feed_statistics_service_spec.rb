describe FeedStatisticsService do
  context 'statistics' do
    it '.generate_statistics' do
      feed_version = create(:feed_version_example)
      FeedStatisticsService.generate_statistics(feed_version)
    end
  end
end
