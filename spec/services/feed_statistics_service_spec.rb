describe FeedStatisticsService do
  context 'statistics' do
    it '.create_feed_version_info' do
      feed_version = create(:feed_version_example)
      feed_stats = FeedStatisticsService.create_feed_version_info(feed_version)
      # expect(feed_stats["routes.txt"][:route_id][:total]).to eq(5)
    end
  end
end
