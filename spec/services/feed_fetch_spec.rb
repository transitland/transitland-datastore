describe FeedFetch do
  let (:url) { 'http://httpbin.org/get' }
  let (:url_redirect) { 'http://httpbin.org/redirect-to?url=http%3A%2F%2Fhttpbin.org%2Fget' }
  let (:url_redirect_many) { 'http://httpbin.org/absolute-redirect/6' }
  let (:url_404) { 'http://httpbin.org/status/404' }
  let (:url_binary) { 'http://httpbin.org/stream-bytes/1024?seed=0' }
  let (:url_ssl) { 'https://httpbin.org/get'}

  context '.fetch' do
    it 'returns a response' do
      VCR.use_cassette('feed_fetch') do
        response = {}
        FeedFetch.fetch(url) { |resp| response = JSON.parse(resp.read_body) }
        expect(response['url']).to eq(url)
      end
    end

    it 'follows a redirect' do
      VCR.use_cassette('feed_fetch_redirect') do
        response = {}
        FeedFetch.fetch(url_redirect) { |resp| response = JSON.parse(resp.read_body) }
        expect(response['url']).to eq(url)
      end
    end

    it 'follows SSL' do
      VCR.use_cassette('feed_fetch_ssl') do
        response = {}
        FeedFetch.fetch(url_ssl) { |resp| response = JSON.parse(resp.read_body) }
        expect(response['url']).to eq(url_ssl)
      end

    end

    it 'follows a redirect no more than limit times' do
      VCR.use_cassette('feed_fetch_redirect_fail') do
        expect {
          FeedFetch.fetch(url_redirect_many, 2) { |resp| response = JSON.parse(resp.read_body) }
        }.to raise_error(ArgumentError)
      end
    end

    it 'raises errors' do
      VCR.use_cassette('feed_fetch_404') do
        expect {
          FeedFetch.fetch(url_404, 2) { |resp| response = JSON.parse(resp.read_body) }
        }.to raise_error(Net::HTTPServerException)
      end
    end
  end

  context '.download_to_tempfile' do
    it 'downloads to temp file' do
      VCR.use_cassette('feed_fetch_download') do
        data = {}
        FeedFetch.download_to_tempfile(url) { |filename| data = JSON.parse(File.read(filename))}
        expect(data['url']).to eq(url)
      end
    end

    it 'removes tempfile' do
      VCR.use_cassette('feed_fetch_download') do
        path = nil
        FeedFetch.download_to_tempfile(url) { |filename| path = filename }
        expect(File.exists?(path)).to be false
      end
    end

    it 'downloads binary data' do
      VCR.use_cassette('feed_fetch_download_binary') do
        data = nil
        FeedFetch.download_to_tempfile(url_binary) { |filename| data = File.read(filename) }
        expect(Digest::MD5.new.update(data).hexdigest).to eq('355c7ebd00db307b91ecd23a4215174a')
      end
    end

    it 'allows files smaller than maximum size' do
      VCR.use_cassette('feed_fetch_download_binary') do
        data = nil
        FeedFetch.download_to_tempfile(url_binary, maxsize=2048) { |filename| data = File.read(filename) }
        expect(Digest::MD5.new.update(data).hexdigest).to eq('355c7ebd00db307b91ecd23a4215174a')
      end
    end

    it 'raises error if response larger than maximum size' do
      VCR.use_cassette('feed_fetch_download_binary') do
        expect {
          FeedFetch.download_to_tempfile(url_binary, maxsize=128) { |filename| }
        }.to raise_error(IOError)
      end
    end
  end
end
