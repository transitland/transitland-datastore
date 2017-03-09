describe FeedValidationWorker do
  before(:each) {
    allow(FeedValidationService).to receive(:run_google_validator) { Tempfile.new(['test','.html']) }
  }

  context 'runs FeedValidationService' do
    it 'attaches output HTML' do
      feed_version = create(:feed_version_example)
      Sidekiq::Testing.inline! do
        FeedValidationWorker.perform_async(feed_version.sha1)
      end
      expect(feed_version.reload.file_feedvalidator.url).to end_with('.html')
    end
  end
end
