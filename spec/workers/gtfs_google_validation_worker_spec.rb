describe GTFSGoogleValidationWorker do
  before(:each) {
    allow(Figaro.env).to receive(:run_google_validator) { 'true' }
    allow(GTFSValidationService).to receive(:run_google_validator) { Tempfile.new(['test','.html']) }
  }

  context 'runs GTFSValidationService' do
    it 'attaches output' do
      feed_version = create(:feed_version_example)
      Sidekiq::Testing.inline! do
        GTFSGoogleValidationWorker.perform_async(feed_version.sha1)
      end
      expect(feed_version.reload.file_feedvalidator.url).to end_with('.html')
    end
  end
end
