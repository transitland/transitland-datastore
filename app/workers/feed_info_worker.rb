require 'net/http'

class FeedInfoWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(url, cachekey)
    feed, operators = nil, nil
    begin
      feed_info = FeedInfo.new(url: url)
      feed_info.open do |f|
        feed, operators = f.parse_feed_and_operators
      end
    rescue GTFS::InvalidSourceException => e
      data = {
        status: 'error',
        url: url,
        exception: 'InvalidSourceException',
        message: 'Invalid GTFS Feed'
      }
    rescue SocketError => e
      data = {
        status: 'error',
        url: url,
        exception: 'SocketError',
        message: 'Error connecting to host'
      }
    rescue Net::HTTPServerException => e
      data = {
        status: 'error',
        url: url,
        exception: 'HTTPServerException',
        message: e.to_s
      }
    rescue StandardError => e
      data = {
        status: 'error',
        url: url,
        exception: e.class.name,
        message: e.to_s
      }
    else
      data = {
        status: 'complete',
        url: url,
        feed: FeedSerializer.new(feed).as_json,
        operators: operators.map { |o| OperatorSerializer.new(o).as_json }
      }
    end
    Rails.cache.write(cachekey, data, expires_in: FeedInfo::CACHE_EXPIRATION)
  end
end

if __FILE__ == $0
  require 'sidekiq/testing'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  url = ARGV[0] || "http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip"
  FeedInfoWorker.perform_async(url, 'asdf')
  FeedInfoWorker.drain
end
