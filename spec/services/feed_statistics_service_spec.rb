describe FeedStatisticsService do
  context 'statistics' do
    it '.run_statistics' do
      feed_version = create(:feed_version_example)
      feed_stats = FeedStatisticsService.run_statistics(feed_version)
      expect(feed_stats["routes.txt"][:route_id][:total]).to eq(5)
    end
  end
end
