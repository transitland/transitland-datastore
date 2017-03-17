describe GTFSStatisticsWorker do
  before(:each) {
  }

  context 'runs GTFSStatisticsService' do
    it 'generates statistics' do
      feed_version = create(:feed_version_example)
      Sidekiq::Testing.inline! do
        GTFSStatisticsWorker.perform_async(feed_version.sha1)
        expect(feed_version.reload.feed_version_info.filenames.size).to eq(12)
      end
    end
  end
end
