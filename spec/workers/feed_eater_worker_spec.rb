require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe FeedEaterWorker do
  before(:each) do
    @feedids = ['f-9q9-caltrain', 'f-9q9-bayarearapidtransit']
    @feeds = @feedids.map {|feedid| Feed.new(onestop_id:feedid)}
  end

  it 'can take a one feed_onestop_id' do
    allow(FeedEaterWorker).to receive(:perform_async) { true }
    FeedEaterWorker.perform_async(@feedids.first)
    Sidekiq::Worker.clear_all
  end

  it 'can take a multiple feed_onestop_ids' do
    allow(FeedEaterWorker).to receive(:perform_async) { true }
    FeedEaterWorker.perform_async(@feedids)
    Sidekiq::Worker.clear_all
  end

  it 'spawns child jobs' do
    allow(Feed).to receive(:update_feeds_from_feed_registry) { true }
    allow(Feed).to receive(:where) { @feeds }
    expect {
      FeedEaterWorker.perform_async(@feedids)
    }.to change(FeedEaterWorker.jobs, :size).by(1)
    expect {
      FeedEaterWorker.drain
    }.to change(FeedEaterFeedWorker.jobs, :size).by(2)
    Sidekiq::Worker.clear_all
  end
end
