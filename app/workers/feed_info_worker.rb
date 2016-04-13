require 'net/http'

class FeedInfoWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(url, cachekey)
    @url = url
    @cachekey = cachekey
    @progress_checkpoint = 0.0
    # Partials
    progress_download = lambda { |count,total| progress_check('downloading', count, total) }
    progress_graph = lambda { |count,total,entity| progress_check('parsing', count, total) }
    # Download & parse feed
    feed, operators = nil, []
    errors = []
    warnings = []
    begin
      # Pass in progress_download, progress_graph callbacks
      gtfs = GTFS::Source.build(
        @url,
        progress_download: progress_download,
        progress_graph: progress_graph,
        strict: false
      )
      feed_info = FeedInfo.new(url: @url, gtfs: gtfs)
      feed, operators = feed_info.parse_feed_and_operators
    rescue GTFS::InvalidURLException => e
      errors << {
        exception: 'InvalidURLException',
        message: 'There was a problem downloading the file. Check the address and try again, or contact the transit operator for more help.'
      }
    rescue GTFS::InvalidResponseException => e
      errors << {
        exception: 'InvalidResponseException',
        message: "There was an error downloading the file. The transit operator server responded with: #{e.to_s}.",
        response_code: e.response_code
      }
    rescue GTFS::InvalidZipException => e
      errors << {
        exception: 'InvalidZipException',
        message: 'The zip file appears to be corrupt.'
      }
    rescue GTFS::InvalidSourceException => e
      errors << {
        exception: 'InvalidSourceException',
        message: 'This file does not appear to be a valid GTFS feed. Contact Transitland for more help.'
      }
    rescue StandardError => e
      errors << {
        exception: e.class.name,
        message: 'There was a problem downloading or processing from this URL.'
      }
    end

    if feed && feed.persisted?
      warnings << {
        onestop_id: feed.onestop_id,
        message: "Existing feed: #{feed.onestop_id}"
      }
    end
    operators.each do |operator|
      if operator && operator.persisted?
        warnings << {
          onestop_id: operator.onestop_id,
          message: "Existing operator: #{operator.onestop_id}"
        }
      end
    end

    response = {}
    response[:feed] = FeedSerializer.new(feed).as_json
    response[:operators] = operators.map { |o| OperatorSerializer.new(o).as_json }
    response[:status] = errors.size > 0 ? 'error' : 'complete'
    response[:errors] = errors
    response[:warnings] = warnings
    response[:url] = url
    Rails.cache.write(cachekey, response, expires_in: FeedInfo::CACHE_EXPIRATION)
    response
  end

  private

  def progress_check(status, count, total)
    # Update upgress if more than 10% work done since last update
    return if total.to_f == 0
    current = count / total.to_f
    if (current - @progress_checkpoint) >= 0.05
      progress_update(status, current)
    end
  end

  def progress_update(status, current)
    # Write progress to cache
    current = 1.0 if current > 1.0
    @progress_checkpoint = current
    cachedata = {
      status: status,
      url: @url,
      progress: current
    }
    Rails.cache.write(@cachekey, cachedata, expires_in: FeedInfo::CACHE_EXPIRATION)
  end
end
