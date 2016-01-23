describe FeedInfo do
  let (:caltrain_url) { 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip' }

  context '.new' do
    it 'requires url or path' do
      expect { FeedInfo.new }.to raise_error(ArgumentError)
    end
  end

  context '.open' do
    it 'downloads if path not provided' do
      VCR.use_cassette('feed_fetch_caltrain') do
        expect { FeedInfo.new(url: caltrain_url).open { |f| f } }.not_to raise_error
      end
    end

    it 'fails with bad host' do
      url = 'http://test.example.com/gtfs.zip'
      VCR.use_cassette('freed_fetch_bad_host') do
        expect { FeedInfo.new(url: url).open { |f| f } }.to raise_error(SocketError)
      end
    end

    it 'raises exception on bad gtfs' do
      url_binary = 'http://httpbin.org/stream-bytes/1024?seed=0'
      VCR.use_cassette('feed_fetch_download_binary') do
        expect { FeedInfo.new(url: url_binary).open { |f| f } }.to raise_error(GTFS::InvalidSourceException)
      end
    end
  end

  context '.parse' do
    let (:path) { Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip') }
    let (:caltrain_feed_info) { FeedInfo.new(url: caltrain_url, path: path) }

    it 'parses feed' do
      feed, operators = nil, nil
      caltrain_feed_info.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
      end
      expect(feed.onestop_id).to eq('f-9q9-wwwcaltraincom')
      expect(feed.url).to eq(caltrain_url)
      expect(feed.geometry).to be_truthy
      expect(feed.operators_in_feed.size).to eq(1)
      expect(feed.operators_in_feed.first.gtfs_agency_id).to eq('caltrain-ca-us')
      expect(feed.operators_in_feed.first.operator.onestop_id).to eq('o-9q9-caltrain')
    end

    it 'parses operators' do
      feed, operators = nil, nil
      caltrain_feed_info.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
      end
      expect(operators.size).to eq(1)
      operator = operators.first
      expect(operator.onestop_id).to eq('o-9q9-caltrain')
      expect(operator.website).to eq('http://www.caltrain.com')
      expect(operator.timezone).to eq('America/Los_Angeles')
      expect(operator.geometry).to be_truthy
    end
  end
end
