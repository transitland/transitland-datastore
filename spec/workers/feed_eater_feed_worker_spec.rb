require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe FeedEaterFeedWorker do
  feedid = 'f-9q9-caltrain'
  feed = Feed.new(onestop_id:feedid)

  it 'accept single onestop_id' do
    expect {
      FeedEaterFeedWorker.perform_async(feedid)
    }.to change(FeedEaterFeedWorker.jobs, :size).by(1)  
    Sidekiq::Worker.clear_all    
  end
  
  it 'returns if feed matches previous hash' do
    allow(Feed).to receive(:find_by) { feed }
    allow_any_instance_of(Feed).to receive(:fetch_and_check_for_updated_version) { false }
    FeedEaterFeedWorker.perform_async(feedid)
    FeedEaterFeedWorker.drain
    Sidekiq::Worker.clear_all    
  end
    
  it 'creates FeedImport record' do
    allow(Feed).to receive(:find_by) { feed }
    allow_any_instance_of(Feed).to receive(:fetch_and_check_for_updated_version) { true }
    allow_any_instance_of(FeedEaterFeedWorker).to receive(:run_python) { false }
    FeedEaterFeedWorker.perform_async(feedid)
    # Check we created a FeedImport record
    expect {
      FeedEaterFeedWorker.drain
    }.to change(FeedImport, :count).by(1)
    Sidekiq::Worker.clear_all    
  end

  # TODO: Additional testing
  #   failure cases
  #   log file upload
  
end
