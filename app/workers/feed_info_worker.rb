require 'net/http'

class FeedInfoWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(url, cachekey)
    feed, operators = nil, nil
    download_to_tempfile(url) do |filename|
      feed, operators = gtfs_feed_operators(url, filename)
    end
    data = {
      status: 'complete',
      url: url,
      feed: FeedSerializer.new(feed).as_json,
      operators: operators.map { |o| OperatorSerializer.new(o).as_json }
    }
    Rails.cache.write(cachekey, data)
  end

  private

  def fetch(url, limit=10, &block)
    # http://ruby-doc.org/stdlib-2.2.3/libdoc/net/http/rdoc/Net/HTTP.html
    # You should choose a better exception.
    raise Exception.new('Too many redirects') if limit == 0
    logger.info "fetch: #{url}"
    url = URI.parse(url)
    Net::HTTP.start(url.host, url.port) do |http|
      http.request_get(url.path) do |response|
        case response
        when Net::HTTPSuccess then
          logger.info "success"
          yield response
        when Net::HTTPRedirection then
          location = response['location']
          logger.info "redirected to #{location}"
          fetch(location, limit-1, &block)
        else
          logger.info "failure"
          raise Exception.new('Failed')
        end
      end
    end
  end

  def download_to_tempfile(url)
    fetch(url) do |response|
      file = Tempfile.new('test.zip', Dir.tmpdir, 'wb')
      file.binmode
      begin
        response.read_body { |chunk| file.write(chunk) }
        file.close
        yield file.path
      ensure
        file.close unless file.closed?
        file.unlink
      end
    end
  end

  def gtfs_feed_operators(url, filename)
    gtfs = GTFS::Source.build(filename, {strict: false})
    gtfs.load_graph
    stop_map = {}
    gtfs.stops.each do |stop|
      stop_map[stop] = Stop.from_gtfs(stop)
    end
    feed = Feed.from_gtfs(url, stop_map.values)
    operators = []
    gtfs.agencies.each do |agency|
      agency_stops = Set.new
      gtfs.children(agency).each do |route|
        gtfs.children(route).each do |trip|
          gtfs.children(trip).each do |stop|
            agency_stops << stop_map[stop]
          end
        end
      end
      operator = Operator.from_gtfs(agency, agency_stops)
      operators << operator
      feed.operators_in_feed.new(gtfs_agency_id: agency.id, operator: operator, id: nil)
    end
    return [feed, operators]
  end

end


if __FILE__ == $0
  require 'sidekiq/testing'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  url = ARGV[0] || "http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip"
  FeedInfoWorker.perform_async(url, 'asdf')
  FeedInfoWorker.drain
end
