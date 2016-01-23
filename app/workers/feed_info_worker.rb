require 'net/http'

class FeedInfoWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(url, cachekey)
    feed, operators = nil, nil
    errors = []
    response = {}
    begin
      feed_info = FeedInfo.new(url: url)
      feed_info.open do |f|
        feed, operators = f.parse_feed_and_operators
      end
    rescue GTFS::InvalidSourceException => e
      errors << {
        exception: 'InvalidSourceException',
        message: 'Invalid GTFS Feed'
      }
    rescue SocketError => e
      errors << {
        exception: 'SocketError',
        message: 'Error connecting to host'
      }
    rescue Net::HTTPServerException => e
      errors << {
        exception: 'HTTPServerException',
        message: e.to_s
      }
    rescue StandardError => e
      errors << {
        exception: e.class.name,
        message: 'Could not download file'
      }
    else
      response[:feed] = FeedSerializer.new(feed).as_json
      response[:operators] = operators.map { |o| OperatorSerializer.new(o).as_json }
    end
    response[:status] = errors.size > 0 ? 'error' : 'complete'
    response[:errors] = errors
    response[:url] = url
    Rails.cache.write(cachekey, response, expires_in: FeedInfo::CACHE_EXPIRATION)
  end
end

if __FILE__ == $0
  require 'sidekiq/testing'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  url = ARGV[0] || "http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip"
  FeedInfoWorker.perform_async(url, 'asdf')
  FeedInfoWorker.drain
end
