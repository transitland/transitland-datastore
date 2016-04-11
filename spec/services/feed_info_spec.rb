describe FeedInfo do
  let (:example_url) { 'https://developers.google.com/transit/gtfs/examples/sample-feed.zip' }
  let (:example_feed_path) { Rails.root.join('spec/support/example_gtfs_archives/example.zip').to_s }

  context '#new' do
    it 'requires url or path' do
      expect { FeedInfo.new }.to raise_error(ArgumentError)
    end
  end

  context '#open' do
    it 'downloads if path not provided' do
      VCR.use_cassette('feed_fetch_example') do
        expect { FeedInfo.new(url: example_url).download { |f| f } }.not_to raise_error
      end
    end
  end

  context '#download' do
    # SocketError is below where VCR can test. Disabled for now.
    # it 'fails with bad host' do
    #   url = 'http://test.example.com/gtfs.zip'
    #   expect { FeedInfo.new(url: url).open { |f| f } }.to raise_error(SocketError)
    # end
  end

  context '#process' do
    it 'raises exception on bad gtfs' do
      # Tests using .open; todo: include an invalid gtfs in spec support.
      url_binary = 'http://httpbin.org/stream-bytes/1024?seed=0'
      VCR.use_cassette('feed_fetch_download_binary') do
        expect { FeedInfo.new(url: url_binary).open { |f| f } }.to raise_error(GTFS::InvalidSourceException)
      end
    end

    it 'passes progress callback' do
      processed = 0
      progress = lambda { |count, total, entity| processed += 1 }
      FeedInfo
        .new(url: example_url, path: example_feed_path)
        .process(progress: progress) { |f| f }
      expect(processed).to eq(54)
    end
  end

  context '#parse_feed_and_operators' do
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

    it 'uses feed_info feed_id' do
      feed, operators = nil, nil
      fi = FeedInfo.new(url: example_url, path: example_feed_path)
      fi.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
      end
      expect(feed.onestop_id).to eq('f-9qs-example')
      expect_geometry = {
        type: 'Polygon',
        coordinates: [[
          [-117.133162, 36.425288],
          [-116.40094, 36.425288],
          [-116.40094, 36.915682],
          [-117.133162, 36.915682],
          [-117.133162, 36.425288]
        ]]
      }
      expect(feed.geometry[:type]).to eq(expect_geometry[:type])
      feed.geometry[:coordinates][0]
        .zip(expect_geometry[:coordinates][0])
        .each { |a,b|
          expect(a[0]).to be_within(0.001).of(b[0])
          expect(a[1]).to be_within(0.001).of(b[1])
        }
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
      expect_geometry = {
        type: 'Polygon',
        coordinates: [[
          [-117.133162, 36.42528800000001],
          [-116.81797, 36.88107999999998],
          [-116.76821000000001, 36.914893],
          [-116.751677, 36.91568199999999],
          [-116.40093999999999, 36.64149599999999],
          [-117.133162, 36.42528800000001]
        ]]
      }
      expect(operator.geometry[:type]).to eq(expect_geometry[:type])
      operator.geometry[:coordinates][0]
        .zip(expect_geometry[:coordinates][0])
        .each { |a,b|
          expect(a[0]).to be_within(0.001).of(b[0])
          expect(a[1]).to be_within(0.001).of(b[1])
        }
    end
  end

  context 'Create Changeset' do
    it 'as_change' do
      feed, operators = nil, nil
      fi = FeedInfo.new(url: example_url, path: example_feed_path)
      fi.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
      end
      # Create changes
      changes = []
      operators.each do |operator|
        changes << {action: 'createUpdate', operator: operator.as_change.compact}
      end
      changes << {action: 'createUpdate', feed: feed.as_change.compact}
      # Apply
      changeset = Changeset.create!
      change_payload = ChangePayload.create!(
        changeset: changeset,
        payload: {changes: changes}
      )
      # binding.pry
      changeset.apply!
      # Test
      f = Feed.find_by_onestop_id!(feed.onestop_id)
      expect(f.onestop_id).to eq feed.onestop_id
      expect(f.operators.map(&:onestop_id)).to match_array(operators.map(&:onestop_id))
    end

    it 'finds existing feeds' do
      existing_feed = create(:feed_example)
      feed, operators = nil, nil
      fi = FeedInfo.new(url: example_url, path: example_feed_path)
      fi.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
      end
      expect(feed.persisted?).to be true
    end

    it 'finds existing operators' do
      existing_operator = create(
        :operator,
        name: 'Demo Transit Authority',
        onestop_id: 'o-9qs-demotransitauthority',
        timezone: 'America/Los_Angeles',
        website: 'http://www.google.com',
        version: 1
      )
      feed, operators = nil, nil
      fi = FeedInfo.new(url: example_url, path: example_feed_path)
      fi.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
      end
      expect(operators.all?(&:persisted?)).to be true
    end
  end
end
