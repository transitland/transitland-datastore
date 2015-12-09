describe FeedInfo do
  let (:url) { 'http://httpbin.org/get' }
  let (:url_redirect) { 'http://httpbin.org/redirect-to?url=http%3A%2F%2Fhttpbin.org%2Fget' }
  let (:url_redirect_many) { 'http://httpbin.org/absolute-redirect/6' }
  let (:url_404) { 'http://httpbin.org/status/404' }
  let (:url_binary) { 'http://httpbin.org/stream-bytes/1024?seed=0' }

  context '#fetch' do
    it 'returns a response' do
      VCR.use_cassette('feed_info_fetch') do
        response = {}
        FeedInfo.fetch(url) { |resp| response = JSON.parse(resp.read_body) }
        expect(response['url']).to eq(url)
      end
    end

    it 'follows a redirect' do
      VCR.use_cassette('feed_info_redirect') do
        response = {}
        FeedInfo.fetch(url_redirect) { |resp| response = JSON.parse(resp.read_body) }
        expect(response['url']).to eq(url)
      end
    end

    it 'follows a redirect no more than limit times' do
      VCR.use_cassette('feed_info_redirect_fail') do
        expect {
          FeedInfo.fetch(url_redirect_many, 2) { |resp| response = JSON.parse(resp.read_body) }
        }.to raise_error(ArgumentError)
      end
    end

    it 'raises errors' do
      VCR.use_cassette('feed_info_404') do
        expect {
          FeedInfo.fetch(url_404, 2) { |resp| response = JSON.parse(resp.read_body) }
        }.to raise_error(Net::HTTPServerException)
      end
    end
  end

  context '#download' do
    it 'downloads to temp file' do
      VCR.use_cassette('feed_info_download') do
        data = {}
        FeedInfo.download_to_tempfile(url) { |filename| data = JSON.parse(File.read(filename))}
        expect(data['url']).to eq(url)
      end
    end

    it 'removes tempfile' do
      VCR.use_cassette('feed_info_download') do
        path = nil
        FeedInfo.download_to_tempfile(url) { |filename| path = filename }
        expect(File.exists?(path)).to be false
      end
    end

    it 'downloads binary data' do
      VCR.use_cassette('feed_info_download_binary') do
        data = nil
        FeedInfo.download_to_tempfile(url_binary) { |filename| data = File.read(filename) }
        expect(Digest::MD5.new.update(data).hexdigest).to eq('355c7ebd00db307b91ecd23a4215174a')
      end
    end

    it 'allows files smaller than maximum size' do
      VCR.use_cassette('feed_info_download_binary') do
        data = nil
        FeedInfo.download_to_tempfile(url_binary, maxsize=2048) { |filename| data = File.read(filename) }
        expect(Digest::MD5.new.update(data).hexdigest).to eq('355c7ebd00db307b91ecd23a4215174a')
      end
    end

    it 'raises error if response larger than maximum size' do
      VCR.use_cassette('feed_info_download_binary') do
        expect {
          FeedInfo.download_to_tempfile(url_binary, maxsize=128) { |filename| }
        }.to raise_error(IOError)
      end
    end
  end

  context '#parse' do
    let (:url) { 'http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip' }
    let (:path) { Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip') }

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
