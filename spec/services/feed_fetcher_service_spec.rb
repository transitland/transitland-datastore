describe FeedFetcherService do
  let(:caltrain_feed) { create(:feed_caltrain) }
  let(:vta_feed) { create(:feed_vta) }

  context 'synchronously' do
    before(:each) do
      allow_any_instance_of(Feed).to receive(:fetch_and_return_feed_version) { true }
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
end
