describe GTFSConveyalValidationWorker do
  before(:each) {
    allow(Figaro.env).to receive(:run_conveyal_validator) { 'true' }
    allow(GTFSValidationService).to receive(:run_conveyal_validator) { Tempfile.new(['test','.json']) }
  }

  context 'runs GTFSValidationService' do
    it 'attaches output' do
      feed_version = create(:feed_version_example)
      Sidekiq::Testing.inline! do
        GTFSConveyalValidationWorker.perform_async(feed_version.sha1)
      end
      expect(feed_version.reload.feed_version_infos.where(type: 'FeedVersionInfoConveyalValidation').count).to eq(1)
    end
  end
end
