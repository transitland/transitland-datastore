describe FeedFetcherWorker do
  it 'fetches the appropriate feed' do
    caltrain = create(:feed_caltrain)
    expect(caltrain.feed_versions.count).to eq 0
    VCR.use_cassette('feed_fetch_caltrain') do
      FeedFetcherWorker.new.perform('f-9q9-caltrain')
    end
    expect(caltrain.feed_versions.count).to eq 1
  end

  it 'fails gracefully if feed not found' do
    expect {
      FeedFetcherWorker.new.perform('f-9q9-caltrain')
    }.not_to raise_error
  end
end
