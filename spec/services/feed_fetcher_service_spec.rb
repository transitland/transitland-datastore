describe FeedFetcherService do
  let(:caltrain_feed) { create(:feed_caltrain) }
  let(:vta_feed) { create(:feed_vta) }
  let (:example_url)              { 'http://localhost:8000/example.zip' }
  let (:example_nested_flat)      { 'http://localhost:8000/example_nested.zip#example_nested/example' }
  let (:example_nested_zip)       { 'http://localhost:8000/example_nested.zip#example_nested/nested/example.zip' }
  let (:example_nested_unambiguous){'http://localhost:8000/example_nested_unambiguous.zip' }
  let (:example_nested_ambiguous) { 'http://localhost:8000/example_nested_ambiguous.zip' }


  let (:example_sha1_raw)         { '2a7503435dcedeec8e61c2e705f6098e560e6bc6' }
  let (:example_nested_sha1_raw)  { '65d278fdd3f5a9fae775a283ef6ca2cb7b961add' }


  context 'synchronously' do
    before(:each) do
      allow(FeedFetcherService).to receive(:fetch_and_return_feed_version) { true }
    end
  end

  context 'asynchronously' do
    it 'fetch_these_feeds_async(feeds)' do
      Sidekiq::Testing.fake! do
        expect {
          FeedFetcherService.fetch_these_feeds_async([caltrain_feed, vta_feed])
        }.to change(FeedFetcherWorker.jobs, :size).by(2)
      end
    end

    it 'fetch_all_feeds_async' do
      present_feeds = [caltrain_feed, vta_feed]
      Sidekiq::Testing.fake! do
        expect {
          FeedFetcherService.fetch_all_feeds_async
        }.to change(FeedFetcherWorker.jobs, :size).by(2)
      end
    end

    it 'fetch_some_ready_feeds_async' do
      present_feeds = [caltrain_feed, vta_feed]
      vta_feed.update(last_fetched_at: 1.hours.ago)
      Sidekiq::Testing.fake! do
        expect {
          FeedFetcherService.fetch_some_ready_feeds_async
        }.to change(FeedFetcherWorker.jobs, :size).by(1)
      end
    end
  end

  context 'fetch_and_return_feed_version' do
    it 'creates a feed version the first time a file is downloaded' do
      feed = create(:feed_caltrain)
      expect(feed.feed_versions.count).to eq 0
      VCR.use_cassette('feed_fetch_caltrain') do
        FeedFetcherService.fetch_and_return_feed_version(feed)
      end
      expect(feed.feed_versions.count).to eq 1
    end

    it 'fetches if status is active' do
      feed = create(:feed_caltrain)
      feed.status = 'active'
      VCR.use_cassette('feed_fetch_caltrain') do
        feed_version = FeedFetcherService.fetch_and_return_feed_version(feed)
        expect(feed_version).to be_truthy
      end
    end

    it 'skips fetch if status is not active' do
      feed = create(:feed_caltrain)
      feed.status = 'broken'
      VCR.use_cassette('feed_fetch_caltrain') do
        feed_version = FeedFetcherService.fetch_and_return_feed_version(feed)
        expect(feed_version).to be_nil
      end
    end

    it "does not create a duplicate, if remote file hasn't changed since last download" do
      feed = create(:feed_caltrain)
      VCR.use_cassette('feed_fetch_caltrain') do
        @feed_version1 = FeedFetcherService.fetch_and_return_feed_version(feed)
      end
      expect(feed.feed_versions.count).to eq 1
      VCR.use_cassette('feed_fetch_caltrain') do
        @feed_version2 = FeedFetcherService.fetch_and_return_feed_version(feed)
      end
      expect(feed.feed_versions.count).to eq 1
      expect(@feed_version1).to eq @feed_version2
    end

    it 'logs fetch errors' do
      feed = create(:feed_caltrain, url: 'http://httpbin.org/status/404')
      expect(feed.feed_versions.count).to eq 0
      VCR.use_cassette('feed_fetch_404') do
        expect(Sidekiq::Logging.logger).to receive(:error).with(/404/)
        FeedFetcherService.fetch_and_return_feed_version(feed)
      end
      expect(feed.feed_versions.count).to eq 0
    end

    it 'saves and deprecates issues from errors' do
      feed = create(:feed_caltrain)
      working_url = feed.url
      feed.update_column(:url, "http://httpbin.org/status/404")
      VCR.use_cassette('feed_fetch_404') do
        FeedFetcherService.fetch_and_return_feed_version(feed)
      end
      expect(Issue.issues_of_entity(feed).count).to eq 1
      feed.update_column(:url, working_url)
      feed.update_column(:last_fetched_at, (FeedFetcherService::REFETCH_WAIT + 3600).ago)
      VCR.use_cassette('feed_fetch_caltrain') do
        FeedFetcherService.fetch_and_return_feed_version(feed)
      end
      expect(Issue.issues_of_entity(feed).count).to eq 0
    end

    it 'creates GTFSGoogleValidationWorker job' do
      allow(Figaro.env).to receive(:run_google_validator) { 'true' }
      feed = create(:feed_caltrain)
      Sidekiq::Testing.fake! do
        expect {
          VCR.use_cassette('feed_fetch_caltrain') do
            FeedFetcherService.fetch_and_return_feed_version(feed)
          end
        }.to change(GTFSGoogleValidationWorker.jobs, :size).by(1)
      end
    end

    it 'creates GTFSConveyalValidationWorker job' do
      allow(Figaro.env).to receive(:run_conveyal_validator) { 'true' }
      feed = create(:feed_caltrain)
      Sidekiq::Testing.fake! do
        expect {
          VCR.use_cassette('feed_fetch_caltrain') do
            FeedFetcherService.fetch_and_return_feed_version(feed)
          end
        }.to change(GTFSConveyalValidationWorker.jobs, :size).by(1)
      end
    end
  end

  context '#url_fragment' do
    it 'returns fragment present' do
      expect(FeedFetcherService.url_fragment(example_nested_zip)).to eq('example_nested/nested/example.zip')
    end

    it 'returns nil if not present' do
      expect(FeedFetcherService.url_fragment(example_url)).to be nil
    end
  end

  context '#read_gtfs_info' do
    it 'reads earliest and latest dates from calendars.txt' do
      feed = create(:feed, url: example_url)
      feed_version = nil
      VCR.use_cassette('feed_fetch_example_local') do
        feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
        feed_version.save!
      end
      expect(feed_version.earliest_calendar_date).to eq Date.parse('2007-01-01')
      expect(feed_version.latest_calendar_date).to eq Date.parse('2010-12-31')
    end

    it 'reads feed_info.txt and puts into tags' do
      feed = create(:feed, url: example_url)
      feed_version = nil
      VCR.use_cassette('feed_fetch_example_local') do
        feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
        feed_version.save!
      end
      expect(feed_version.tags['feed_lang']).to eq 'en-US'
      expect(feed_version.tags['feed_version']).to eq '1.0'
      expect(feed_version.tags['feed_publisher_url']).to eq 'http://google.com'
      expect(feed_version.tags['feed_publisher_name']).to eq 'Google'
    end
  end

  context '#gtfs_minimal_validation' do
    it 'raises exception when missing a required file' do
      file = Rails.root.join('spec/support/example_gtfs_archives/example-missing-stops.zip')
      expect {
        gtfs = FeedFetcherService.fetch_gtfs(file: file)
        FeedFetcherService.gtfs_minimal_validation(gtfs)
      }.to raise_error(GTFS::InvalidSourceException)
    end

    it 'raises exception when a required file is empty' do
      file = Rails.root.join('spec/support/example_gtfs_archives/example-empty-stops.zip')
      gtfs = FeedFetcherService.fetch_gtfs(file: file)
      expect {
        FeedFetcherService.gtfs_minimal_validation(gtfs)
      }.to raise_error(GTFS::InvalidSourceException)
    end

    it 'raises exception when calendar is empty' do
      file = Rails.root.join('spec/support/example_gtfs_archives/example-empty-calendar.zip')
      gtfs = FeedFetcherService.fetch_gtfs(file: file)
      expect {
        FeedFetcherService.gtfs_minimal_validation(gtfs)
      }.to raise_error(GTFS::InvalidSourceException)
    end
  end

  context '#fetch_normalize_validate_create' do
    it 'downloads feed' do
      feed = create(:feed, url: example_url)
      feed_version = nil
      VCR.use_cassette('feed_fetch_example_local') do
        feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
        feed_version.save!
      end
      expect(feed_version.sha1).to eq example_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes feed' do
      feed = create(:feed, url: example_url)
      feed_version = nil
      VCR.use_cassette('feed_fetch_example_local') do
        feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
        feed_version.save!
      end
      expect(feed_version.sha1).to be_truthy # eq example_sha1
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes nested gtfs zip' do
      feed = create(:feed, url: example_nested_zip)
      feed_version = nil
      VCR.use_cassette('feed_fetch_nested') do
        feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
        feed_version.save!
      end
      expect(feed_version.sha1).to be_truthy # eq example_nested_sha1_zip
      expect(feed_version.sha1_raw).to eq example_nested_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes nested gtfs flat' do
      feed = create(:feed, url: example_nested_flat)
      feed_version = nil
      VCR.use_cassette('feed_fetch_nested') do
        feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
        feed_version.save!
      end
      expect(feed_version.sha1).to be_truthy # eq example_nested_sha1_flat
      expect(feed_version.sha1_raw).to eq example_nested_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'auto_detect_root unambiguous' do
      # Note: when root is auto-detected, a raw file is not created.
      feed = create(:feed, url: example_nested_unambiguous)
      feed_version = nil
      VCR.use_cassette('example_nested_unambiguous') do
        feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
        feed_version.save!
      end
      expect(feed_version.sha1).to eq('ab14bc8689f27acbb9d0e3a0dbf7006da96734bc')
      expect(feed_version.sha1_raw).to be_nil
    end

    it 'auto_detect_root ambiguous' do
      feed = create(:feed, url: example_nested_ambiguous)
      expect {
        VCR.use_cassette('example_nested_ambiguous') do
          feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
          feed_version.save!
        end
      }.to raise_error(GTFS::AmbiguousZipException)
    end

    it 'normalizes consistent sha1' do
      feed = create(:feed, url: example_nested_flat)
      feed_version = nil
      feed_versions = []
      2.times.each do |i|
        VCR.use_cassette('feed_fetch_nested') do
          feed_version = FeedFetcherService.fetch_normalize_validate_create(feed, url: feed.url)
        end
        feed_versions << feed_version
        sleep 5
      end
      fv1, fv2 = feed_versions
      expect(fv1.sha1).to eq fv2.sha1
    end
  end

end
