describe GTFSStatisticsService do
  context '.create_feed_version_info_statistics' do
    it 'creates FeedVersionInfoStatistics' do
      feed_version = create(:feed_version_example)
      feed_version_info = GTFSStatisticsService.create_feed_version_info_statistics(feed_version)
      data = feed_version_info.data
      expect(data['filenames']).to contain_exactly(
        "LICENSE.txt",
        "agency.txt",
        "calendar.txt",
        "calendar_dates.txt",
        "fare_attributes.txt",
        "fare_rules.txt",
        "feed_info.txt",
        "frequencies.txt",
        "routes.txt",
        "shapes.txt",
        "stop_times.txt",
        "stops.txt",
        "trips.txt"
      )
      expect(data['scheduled_service'].size).to eq(1460)
      expect(data['statistics']['routes.txt']['agency_id']['total']).to eq(5)
      expect(data['statistics']['routes.txt']['agency_id']['unique']).to eq(1)
    end

    it 'creates FeedVersionInfoStatistics with exception' do
      allow(GTFSStatisticsService).to receive(:run_statistics) { fail StandardError.new('test') }
      feed_version = create(:feed_version_example)
      feed_version_info = GTFSStatisticsService.create_feed_version_info_statistics(feed_version)
      expect(feed_version_info.data["error"]).to eq("test")
    end
  end
end
