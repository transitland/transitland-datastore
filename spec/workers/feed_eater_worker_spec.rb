describe FeedEaterWorker do
  before(:each) do
    create(:feed_version_caltrain)
    create(:feed_version_bart)
  end

  it 'can take a one feed_onestop_id' do
    allow(FeedEaterWorker).to receive(:perform_async) { true }
    FeedEaterWorker.perform_async('f-9q9-bart')
    Sidekiq::Worker.clear_all
  end

  it 'can take a multiple feed_onestop_ids' do
    allow(FeedEaterWorker).to receive(:perform_async) { true }
    FeedEaterWorker.perform_async(['f-9q9-bart', 'f-9q9-caltrain'])
    Sidekiq::Worker.clear_all
  end

  it 'spawns child jobs' do
    expect {
      FeedEaterWorker.perform_async(['f-9q9-bart', 'f-9q9-caltrain'])
    }.to change(FeedEaterWorker.jobs, :size).by(1)
    expect {
      FeedEaterWorker.drain
    }.to change(FeedEaterFeedWorker.jobs, :size).by(2)
    Sidekiq::Worker.clear_all
  end
end
