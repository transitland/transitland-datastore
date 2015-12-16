require 'net/http'

class FeedInfo
  CACHE_EXPIRATION = 1.hour

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

  def self.download_to_tempfile(url, maxsize=nil)
    fetch(url) do |response|
      file = Tempfile.new('test.zip', Dir.tmpdir)
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

  def self.parse_feed_and_operators(url, filename)
    # load feed
    gtfs = GTFS::Source.build(filename, {strict: false})
    gtfs.load_graph
    # find visited stops
    stop_map = {}
    agency_visited_stops = {}
    feed_visited_stops = Set.new
    gtfs.agencies.each do |agency|
      visited_stops = Set.new
      gtfs.children(agency).each do |route|
        gtfs.children(route).each do |trip|
          gtfs.children(trip).each do |stop|
            stop_map[stop] ||= Stop.from_gtfs(stop)
            visited_stops << stop_map[stop]
          end
        end
      end
      agency_visited_stops[agency] = visited_stops
      feed_visited_stops |= visited_stops
    end
    # feed
    feed = Feed.from_gtfs(url, feed_visited_stops)
    # operators
    operators = []
    gtfs.agencies.each do |agency|
      operator = Operator.from_gtfs(agency, agency_visited_stops[agency])
      operators << operator
      feed.operators_in_feed.new(gtfs_agency_id: agency.id, operator: operator, id: nil)
    end
    # done
    return [feed, operators]
  end
end
