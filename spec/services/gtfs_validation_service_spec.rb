describe GTFSValidationService do
  context '.run_validators' do
    before(:each) {
      allow(Figaro.env).to receive(:run_google_validator) { 'true' }
      allow(Figaro.env).to receive(:run_conveyal_validator) { 'true' }
      allow(GTFSValidationService).to receive(:run_google_validator) { Tempfile.new(['test','.html']) }
      allow(GTFSValidationService).to receive(:run_conveyal_validator) { Tempfile.new(['test','.json']) }
    }

    it '.run_validators' do
      feed_version = create(:feed_version_example)
      expect(feed_version.reload.file_feedvalidator.url).to be nil
      GTFSValidationService.run_validators(feed_version)
      expect(feed_version.reload.file_feedvalidator.url).to end_with('.html')
      expect(feed_version.reload.feed_version_infos.where(type: 'FeedVersionInfoConveyalValidation').count).to eq(1)
    end
  end

  context '.create_feed_version_info_conveyal_validation' do
    it 'creates FeedVersionInfoConveyalValidation record' do
      allow(GTFSValidationService).to receive(:run_conveyal_validator) {
        a = Tempfile.new(['test','.json'])
        a.write({foo: 'bar'}.to_json)
        a.close
        File.open(a.path)
      }
      feed_version = create(:feed_version_example)
      feed_version_info = GTFSValidationService.create_feed_version_info_conveyal_validation(feed_version)
      expect(feed_version_info.data["foo"]).to eq("bar")
    end

    it 'creates FeedVersionInfoConveyalValidation with exception' do
      allow(GTFSValidationService).to receive(:run_conveyal_validator) { fail StandardError.new('test') }
      feed_version = create(:feed_version_example)
      feed_version_info = GTFSValidationService.create_feed_version_info_conveyal_validation(feed_version)
      expect(feed_version_info.data["error"]).to eq("test")
    end

    it 'creates FeedVersionInfoConveyalValidation with error for empty file' do
      allow(GTFSValidationService).to receive(:run_conveyal_validator) { nil }
      feed_version = create(:feed_version_example)
      feed_version_info = GTFSValidationService.create_feed_version_info_conveyal_validation(feed_version)
      expect(feed_version_info.data["error"]).to eq("No output")
    end
  end

  context '.create_feed_version_info_google_validation' do
    it 'saves results' do
      allow(GTFSValidationService).to receive(:run_google_validator) { Tempfile.new(['test','.html']) }
      feed_version = create(:feed_version_example)
      GTFSValidationService.create_google_validation(feed_version)
      expect(feed_version.reload.file_feedvalidator.url).to end_with('.html')
    end
  end
end
