describe GTFSStatisticsService do
  context 'statistics' do
    it '.create_feed_version_info' do
      feed_version = create(:feed_version_example)
      feed_version_info = GTFSStatisticsService.create_feed_version_info(feed_version)
      expect(feed_version_info.filenames.size).to eq(12)
      expect(feed_version_info.scheduled_service.size).to eq(1460)
      expect(feed_version_info.statistics.size).to eq(12)
      expect(feed_version_info.statistics['routes.txt']['agency_id']['total']).to eq(5)
      expect(feed_version_info.statistics['routes.txt']['agency_id']['unique']).to eq(1)
    end
  end
end
