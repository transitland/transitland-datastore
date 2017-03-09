describe FeedValidationService do
  context 'validators' do
    before(:each) {
      allow(FeedValidationService).to receive(:run_google_feedvalidator) { Tempfile.new(['test','.html']) }
    }

    it '.run_validators' do
      feed_version = create(:feed_version_example)
      expect(feed_version.reload.file_feedvalidator.url).to be nil
      FeedValidationService.run_validators(feed_version)
      expect(feed_version.reload.file_feedvalidator.url).to end_with('.html')
    end
  end
end
