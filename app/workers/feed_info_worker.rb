require 'net/http'

class FeedInfoWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(url, cachekey)
    feed, operators = nil, nil
    FeedInfo.download_to_tempfile(url) do |filename|
      feed, operators = FeedInfo.parse_feed_and_operators(url, filename)
    end
    data = {
      status: 'complete',
      url: url,
      feed: FeedSerializer.new(feed).as_json,
      operators: operators.map { |o| OperatorSerializer.new(o).as_json }
    }
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
