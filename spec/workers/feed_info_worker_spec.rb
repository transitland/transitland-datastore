describe FeedInfoWorker do
  it 'writes feed info to cache' do
    url = 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip'
    cachekey = 'test'
    Rails.cache.delete(cachekey)
    VCR.use_cassette('fetch_caltrain') do
      FeedInfoWorker.new.perform(url, cachekey)
    end
    cachedata = Rails.cache.read(cachekey)
    expect(cachedata[:status]).to eq('complete')
    expect(cachedata[:url]).to eq(url)
    expect(cachedata[:feed][:onestop_id]).to eq('f-9q9-wwwcaltraincom')
    expect(cachedata[:operators].size).to eq(1)
    expect(cachedata[:operators].first[:onestop_id]).to eq('o-9q9-caltrain')
  end

  it 'fails with status message' do
    url = 'http://www.bart.gov/this-is-a-bad-url.zip'
    cachekey = 'test'
    Rails.cache.delete(cachekey)
    VCR.use_cassette('fetch_bart_404') do
      FeedInfoWorker.new.perform(url, cachekey)
    end
    cachedata = Rails.cache.read(cachekey)
    expect(cachedata[:status]).to eq('error')
    expect(cachedata[:exception]).to eq('Net::HTTPServerException')
    expect(cachedata[:message]).to eq('404 "Not Found"')
  end
end
