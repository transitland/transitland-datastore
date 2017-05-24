describe GTFSStatisticsWorker do
  before(:each) {
  }

  context 'runs GTFSStatisticsService' do
    it 'generates statistics' do
      feed_version = create(:feed_version_example)
      Sidekiq::Testing.inline! do
        GTFSStatisticsWorker.perform_async(feed_version.sha1)
        fvi = feed_version.reload.feed_version_infos.first
        expect(fvi.data['filenames'].size).to eq(13)
      end
    end
  end
end
