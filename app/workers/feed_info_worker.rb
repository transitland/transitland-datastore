require 'net/http'

class FeedInfoWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(url, cachekey)
    error, feed, operators = nil, nil, nil
    begin
      FeedInfo.download_to_tempfile(url, maxsize=100*1024*1024) do |filename|
        feed, operators = FeedInfo.parse_feed_and_operators(url, filename)
      end
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
    Rails.cache.write(cachekey, data)
  end
end

if __FILE__ == $0
  require 'sidekiq/testing'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  url = ARGV[0] || "http://www.caltrain.com/Assets/GTFS/caltrain/GTFS-Caltrain-Devs.zip"
  FeedInfoWorker.perform_async(url, 'asdf')
  FeedInfoWorker.drain
end
