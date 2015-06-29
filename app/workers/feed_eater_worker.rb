class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids = [])
    logger.info 'FeedEaterWorker: Update feeds from feed registry'
    Feed.update_feeds_from_feed_registry
    feeds = feed_onestop_ids.length > 0 ? Feed.where(onestop_id: feed_onestop_ids) : Feed.where('')
    feeds.each do |feed|
      FeedEaterFeedWorker.perform_async(feed.onestop_id)
    end
  end

  private

  def run_python(file, *args)
    python = Figaro.env.python_path || './virtualenv/bin/python'
    success = system(
      python,
      file,
      *args
    )
    raise "Error running Python: #{file} #{args}" if !success
  end

  def artifact_file_path(name)
    path = Figaro.env.transitland_feed_data_path
    raise "Must specify TRANSITLAND_FEED_DATA_PATH" if !path
    File.join(path, name)
  end

end
