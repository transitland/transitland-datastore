describe FeedInfo do
  let (:url) { 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip' }
  let (:path) { Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip') }

  context 'fetch' do

  end

  context 'download' do

  end

  context 'parse' do
    it 'parses feed' do
      feed, operators = FeedInfo.parse_feed_and_operators(url, path)
      expect(feed.onestop_id).to eq('f-9q9-wwwcaltraincom')
      expect(feed.url).to eq(url)
      expect(feed.geometry).to be_truthy
      expect(feed.operators_in_feed.size).to eq(1)
      expect(feed.operators_in_feed.first.gtfs_agency_id).to eq('caltrain-ca-us')
      expect(feed.operators_in_feed.first.operator.onestop_id).to eq('o-9q9-caltrain')
    end

    it 'parses operators' do
      feed, operators = FeedInfo.parse_feed_and_operators(url, path)
      expect(operators.size).to eq(1)
      operator = operators.first
      expect(operator.onestop_id).to eq('o-9q9-caltrain')
      expect(operator.website).to eq('http://www.caltrain.com')
      expect(operator.timezone).to eq('America/Los_Angeles')
      expect(operator.geometry).to be_truthy
    end
  end
end
