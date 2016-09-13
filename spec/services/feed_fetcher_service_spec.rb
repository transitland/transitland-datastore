describe FeedFetcherService do
  let(:caltrain_feed) { create(:feed_caltrain) }
  let(:vta_feed) { create(:feed_vta) }
  let (:example_url)              { 'http://localhost:8000/example.zip' }
  let (:example_nested_flat)      { 'http://localhost:8000/example_nested.zip#example_nested/example' }
  let (:example_nested_zip)       { 'http://localhost:8000/example_nested.zip#example_nested/nested/example.zip' }
  let (:example_sha1_raw)         { '2a7503435dcedeec8e61c2e705f6098e560e6bc6' }
  let (:example_nested_sha1_raw)  { '65d278fdd3f5a9fae775a283ef6ca2cb7b961add' }


  context 'synchronously' do
    before(:each) do
      allow(FeedFetcherService).to receive(:fetch_and_return_feed_version) { true }
    end

    it 'fetch_this_feed_now(feed)' do
      FeedFetcherService.fetch_this_feed_now(caltrain_feed)
    end

    it 'fetch_these_feeds_now(feeds)' do
      FeedFetcherService.fetch_these_feeds_now([caltrain_feed, vta_feed])
    end
  end

  context 'asynchronously' do
    it 'fetch_this_feed_async(feed)' do
      # Sidekiq::Testing.fake! do
        expect {
          FeedFetcherService.fetch_this_feed_async(caltrain_feed)
        }.to change(FeedFetcherWorker.jobs, :size).by(1)
      # end
    end

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
      vta_feed.update(last_fetched_at: 48.hours.ago)
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
        FeedFetcherService.fetch_and_return_feed_version(feed)
      end
      expect(feed.feed_versions.count).to eq 0
      expect(feed.latest_fetch_exception_log).to be_present
      expect(feed.latest_fetch_exception_log).to include('404')
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

  context '#fetch_and_normalize' do
    it 'downloads feed' do
      feed = create(:feed, url: example_url)
      feed_version = nil
      VCR.use_cassette('feed_fetch_example_local') do
        feed_version = FeedFetcherService.fetch_and_normalize_feed_version(feed)
        feed_version.save!
      end
      expect(feed_version.sha1).to eq example_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes feed' do
      feed = create(:feed, url: example_url)
      feed_version = nil
      VCR.use_cassette('feed_fetch_example_local') do
        feed_version = FeedFetcherService.fetch_and_normalize_feed_version(feed)
        feed_version.save!
      end
      expect(feed_version.sha1).to be_truthy # eq example_sha1
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes nested gtfs zip' do
      feed = create(:feed, url: example_nested_zip)
      feed_version = nil
      VCR.use_cassette('feed_fetch_nested') do
        feed_version = FeedFetcherService.fetch_and_normalize_feed_version(feed)
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
        feed_version = FeedFetcherService.fetch_and_normalize_feed_version(feed)
        feed_version.save!
      end
      expect(feed_version.sha1).to be_truthy # eq example_nested_sha1_flat
      expect(feed_version.sha1_raw).to eq example_nested_sha1_raw
      expect(feed_version.fetched_at).to be_truthy
    end

    it 'normalizes consistent sha1' do
      feed = create(:feed, url: example_nested_flat)
      feed_version = nil
      feed_versions = []
      2.times.each do |i|
        VCR.use_cassette('feed_fetch_nested') do
          feed_version = FeedFetcherService.fetch_and_normalize_feed_version(feed)
        end
        feed_versions << feed_version
        sleep 5
      end
      fv1, fv2 = feed_versions
      expect(fv1.sha1).to eq fv2.sha1
      expect(fv1.fetched_at).not_to eq(fv2.fetched_at)
    end

    # it 'fails if files already exist' do
    #   feed_version = create(:feed_version_bart)
    #   VCR.use_cassette('feed_fetch_bart') do
    #     expect { feed_version.fetch_and_normalize }.to raise_error(StandardError)
    #   end
    # end
  end

end
