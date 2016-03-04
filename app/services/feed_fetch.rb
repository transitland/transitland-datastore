require 'net/http'

module FeedFetch
  def self.download_to_tempfile(url, maxsize: nil, progress: nil)
    progress ||= lambda { |count, total| }
    fetch(url) do |response|
      count = 0
      total = response.content_length
      file = Tempfile.new(['fetched-feed', '.zip'])
      file.binmode
      begin
        response.read_body do |chunk|
          file.write(chunk)
          count += chunk.size
          progress.call(count, total)
        end
        raise IOError.new('Exceeds maximum file size') if (maxsize && count > maxsize)
        file.close
        yield file.path
      ensure
        file.close unless file.closed?
        file.unlink
      end
    end
  end

  private

  def self.fetch(url, limit:10, timeout:60, &block)
    # http://ruby-doc.org/stdlib-2.2.3/libdoc/net/http/rdoc/Net/HTTP.html
    # You should choose a better exception.
    # Some improvements inspired by
    #   https://gist.github.com/sekrett/7dd4177d6c87cf8265cd
    raise ArgumentError.new('Too many redirects') if limit == 0
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = timeout
    http.read_timeout = timeout
    if url.instance_of?(URI::HTTPS)
      http.use_ssl = true
    end
    http.request_get(url.request_uri) do |response|
      case response
      when Net::HTTPRedirection then
        fetch(
          response['location'],
          limit:limit-1,
          timeout:timeout,
          &block
        )
      when Net::HTTPSuccess then
        yield response
      else
        raise response.value
      end
    end
  end
end
