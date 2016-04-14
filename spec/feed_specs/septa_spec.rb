describe 'SEPTA', optional: true do
  let(:url) { 'https://github.com/septadev/GTFS/releases/download/v20160410.2/gtfs_public.zip' }
  let(:url_rail) { "#{url}#google_rail.zip" }
  let(:url_bus) { "#{url}#google_bus.zip" }
  let(:feed) {
    feed = create(:feed, url: url_rail, onestop_id: 'f-dr4-septa')
    operator = create(:operator, onestop_id: 'o-dr4-septa')
    feed.operators_in_feed.create!(operator: operator, gtfs_agency_id: 'SEPTA')
    feed
  }

  context 'FeedInfo' do
    it 'base url is invalid' do
      VCR.use_cassette('feed_fetch_septa') do
        expect { FeedInfo.new(url: url).open }.to raise_error(GTFS::InvalidSourceException)
      end
    end

    it 'parses nested rail feed' do
      feed, operators = nil, nil
      VCR.use_cassette('feed_fetch_septa') do
        FeedInfo.new(url: url_rail).open { |fi| feed, operators = fi.parse_feed_and_operators }
      end
      expect(feed.onestop_id).to eq('f-dr4-septa')
      expect(operators.size).to eq(1)
      expect(operators.first.onestop_id).to eq('o-dr4-septa')
    end

    # Slow
    # it 'parses nested bus feed' do
    #   feed, operators = nil, nil
    #   VCR.use_cassette('feed_fetch_septa') do
    #     FeedInfo.new(url: url_bus).open { |fi| feed, operators = fi.parse_feed_and_operators }
    #   end
    #   expect(feed.onestop_id).to eq('f-dr4-septa')
    #   expect(operators.size).to eq(1)
    #   expect(operators.first.onestop_id).to eq('o-dr4-septa')
    # end
  end

  context 'FeedVersion' do
    it 'downloads and normalizes' do
      feed_version = feed.feed_versions.new(url: url_rail)
      VCR.use_cassette('feed_fetch_septa') do
        feed_version.fetch_and_normalize
      end
      expect(feed_version.sha1_raw).to eq('7753eb566a28e29119475da6b3b03b3fc0922b3d')
      expect(feed_version.sha1).to be_truthy
    end
  end

  context 'GTFSGraph' do
    it 'imports' do
      feed_version = nil
      VCR.use_cassette('feed_fetch_septa') do
        feed_version = feed.fetch_and_return_feed_version
      end
      expect(feed_version.sha1_raw).to eq('7753eb566a28e29119475da6b3b03b3fc0922b3d')
      load_feed(feed_version: feed_version)
      expect(Stop.count).to eq(155)
      expect(Route.count).to eq(13)
    end
  end
end
