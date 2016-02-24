describe FeedInfo do
  let (:example_url) { 'https://developers.google.com/transit/gtfs/examples/sample-feed.zip' }
  let (:example_feed_path) { Rails.root.join('spec/support/example_gtfs_archives/example.zip') }

  context '.new' do
    it 'requires url or path' do
      expect { FeedInfo.new }.to raise_error(ArgumentError)
    end
  end

  context '.open' do
    it 'downloads if path not provided' do
      VCR.use_cassette('feed_fetch_example') do
        expect { FeedInfo.new(url: example_url).open { |f| f } }.not_to raise_error
      end
    end

    # SocketError is below where VCR can test. Disabled for now.
    # it 'fails with bad host' do
    #   url = 'http://test.example.com/gtfs.zip'
    #   expect { FeedInfo.new(url: url).open { |f| f } }.to raise_error(SocketError)
    # end

    it 'raises exception on bad gtfs' do
      url_binary = 'http://httpbin.org/stream-bytes/1024?seed=0'
      VCR.use_cassette('feed_fetch_download_binary') do
        expect { FeedInfo.new(url: url_binary).open { |f| f } }.to raise_error(GTFS::InvalidSourceException)
      end
    end
  end

  context '.parse' do
    it 'parses feed' do
      feed, operators = nil, nil
      fi = FeedInfo.new(url: example_url, path: example_feed_path)
      fi.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
      end
      expect(feed.onestop_id).to eq('f-9qs-example')
      expect(feed.url).to eq(example_url)
      expect(feed.geometry).to be_truthy
      expect(feed.operators_in_feed.size).to eq(1)
      expect(feed.operators_in_feed.first.gtfs_agency_id).to eq('DTA')
      expect(feed.operators_in_feed.first.operator.onestop_id).to eq('o-9qs-demotransitauthority')
    end

    end

    it 'parses operators' do
      feed, operators = nil, nil
      fi = FeedInfo.new(url: example_url, path: example_feed_path)
      fi.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
      end
      expect(operators.size).to eq(1)
      operator = operators.first
      expect(operator.onestop_id).to eq('o-9qs-demotransitauthority')
      expect(operator.website).to eq('http://google.com')
      expect(operator.timezone).to eq('America/Los_Angeles')
      expect(operator.geometry).to be_truthy
    end
  end
end
