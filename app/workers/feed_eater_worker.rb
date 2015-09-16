class FeedEaterWorker
  include Sidekiq::Worker

  def perform(feed_onestop_ids = [], import_level = 0)
    feeds = feed_onestop_ids.length > 0 ? Feed.where(onestop_id: feed_onestop_ids) : Feed.where('')
    feeds.each do |feed|
      logger.info "FeedEaterWorker: Enqueue #{feed.onestop_id} at import level #{import_level}"
      FeedEaterFeedWorker.perform_async(feed.onestop_id, import_level)
    end
    logger.info 'FeedEaterWorker: Done.'
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
