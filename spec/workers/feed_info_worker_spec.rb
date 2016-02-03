describe FeedInfoWorker do
  it 'writes feed info to cache' do
    url = 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip'
    cachekey = 'test'
    Rails.cache.delete(cachekey)
    VCR.use_cassette('feed_fetch_caltrain') do
      FeedInfoWorker.new.perform(url, cachekey)
    end
    cachedata = Rails.cache.read(cachekey)
    expect(cachedata[:status]).to eq('complete')
    expect(cachedata[:url]).to eq(url)
    expect(cachedata[:feed][:onestop_id]).to eq('f-9q9-wwwcaltraincom')
    expect(cachedata[:operators].size).to eq(1)
    expect(cachedata[:operators].first[:onestop_id]).to eq('o-9q9-caltrain')
  end

  it 'fails with 404' do
    url = 'http://www.bart.gov/this-is-a-bad-url.zip'
    cachekey = 'test'
    Rails.cache.delete(cachekey)
    VCR.use_cassette('feed_fetch_bart_404') do
      FeedInfoWorker.new.perform(url, cachekey)
    end
    cachedata = Rails.cache.read(cachekey)
    expect(cachedata[:status]).to eq('error')
    expect(cachedata[:errors].first[:exception]).to eq('HTTPServerException')
    expect(cachedata[:errors].first[:message]).to eq('404 "Not Found"')
    expect(cachedata[:errors].first[:response_code]).to eq('404')
  end

  it 'fails with bad host' do
    url = 'http://test.example.com/gtfs.zip'
    cachekey = 'test'
    Rails.cache.delete(cachekey)
    VCR.use_cassette('feed_fetch_bad_host') do
      FeedInfoWorker.new.perform(url, cachekey)
    end
    cachedata = Rails.cache.read(cachekey)
    expect(cachedata[:status]).to eq('error')
    expect(cachedata[:errors].first[:exception]).to eq('SocketError')
  end

  it 'fails with invalid gtfs' do
    url = 'http://httpbin.org/stream-bytes/1024?seed=0'
    cachekey = 'test'
    Rails.cache.delete(cachekey)
    VCR.use_cassette('feed_fetch_download_binary') do
      FeedInfoWorker.new.perform(url, cachekey)
    end
    cachedata = Rails.cache.read(cachekey)
    expect(cachedata[:status]).to eq('error')
    expect(cachedata[:errors].first[:exception]).to eq('InvalidSourceException')
    expect(cachedata[:errors].first[:message]).to eq('Invalid GTFS Feed')
  end
end
