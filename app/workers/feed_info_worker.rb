require 'net/http'

class FeedInfoWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(url, cachekey)
    feed, operators = nil, []
    warnings = []
    errors = []
    begin
      feed_info = FeedInfo.new(url: url)
      feed_info.open do |f|
        feed, operators = f.parse_feed_and_operators
      end
    rescue GTFS::InvalidSourceException => e
      errors << {
        exception: 'InvalidSourceException',
        message: 'This file does not appear to be a valid GTFS feed. Contact Transitland for more help.'
      }
    rescue SocketError => e
      errors << {
        exception: 'SocketError',
        message: 'There was a problem downloading the file. Check the address and try again, or contact the transit operator for more help.'
      }
    rescue Net::HTTPServerException => e
      errors << {
        exception: 'HTTPServerException',
        message: "There was an error downloading the file. The transit operator server responded with: #{e.to_s}.",
        response_code: e.response.code
      }
    rescue StandardError => e
      errors << {
        exception: e.class.name,
        message: 'There was a problem downloading or processing from this URL.'
      }
    else
      response[:feed] = FeedSerializer.new(feed).as_json
      response[:operators] = operators.map { |o| OperatorSerializer.new(o).as_json }
    end

    if feed && feed.persisted?
      warnings << {
        feed_onestop_id: feed.onestop_id,
        message: "Existing feed: #{feed.onestop_id}"
      }
    end
    operators.each do |operator|
      if operator && operator.persisted?
        warnings << {
          operator_onestop_id: operator.onestop_id,
          message: "Existing operator: #{operator.onestop_id}"
        }
      end
    end

    response = {}
    response[:status] = errors.size > 0 ? 'error' : 'complete'
    response[:errors] = errors
    response[:warnings] = warnings
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
