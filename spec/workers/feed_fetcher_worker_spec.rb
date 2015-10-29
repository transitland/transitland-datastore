describe FeedFetcherWorker do
  it 'fetches the appropriate feed' do
    bart = create(:feed_bart)
    caltrain = create(:feed_caltrain)

    VCR.use_cassette('fetch_caltrain') do
      FeedFetcherWorker.new.perform('f-9q9-caltrain')
    end

    expect(caltrain.feed_versions.count).to eq 1
    expect(bart.feed_versions.count).to eq 0
  end

  it 'fails gracefully if feed not found' do
    expect {
      FeedFetcherWorker.new.perform('f-9q9-caltrain')
    }.not_to raise_error
  end
end
