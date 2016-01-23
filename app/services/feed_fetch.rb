require 'net/http'

module FeedFetch
  def self.download_to_tempfile(url, maxsize=nil)
    fetch(url) do |response|
      file = Tempfile.new(['fetched-feed', '.zip'])
      file.binmode
      total = 0
      begin
        response.read_body do |chunk|
          file.write(chunk)
          total += chunk.size
        end
        raise IOError.new('Exceeds maximum file size') if (maxsize && total > maxsize)
        file.close
        yield file.path
      ensure
        file.close unless file.closed?
        file.unlink
      end
    end
  end

  private

  def self.fetch(url, limit=10, &block)
    # http://ruby-doc.org/stdlib-2.2.3/libdoc/net/http/rdoc/Net/HTTP.html
    # You should choose a better exception.
    raise ArgumentError.new('Too many redirects') if limit == 0
    url = URI.parse(url)
    Net::HTTP.start(url.host, url.port) do |http|
      http.request_get(url.request_uri) do |response|
        case response
        when Net::HTTPSuccess then
          yield response
        when Net::HTTPRedirection then
          fetch(response['location'], limit-1, &block)
        else
          raise response.value
        end
      end
    end
  end
end
