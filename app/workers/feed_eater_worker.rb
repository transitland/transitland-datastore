class FeedEaterWorker
  include Sidekiq::Worker

  PYTHON = './virtualenv/bin/python'
  FEEDVALIDATOR = './virtualenv/bin/feedvalidator.py'

  def perform(feed_onestop_ids = [])
    logger.info '0. update feeds from feed registry'
    Feed.update_feeds_from_feed_registry

    logger.info '1. fetch and check feeds for updated versions'
    updated_feed_onestop_ids = Feed.fetch_and_check_for_updated_version(feed_onestop_ids).map(&:onestop_id)

    if updated_feed_onestop_ids.length == 0
      logger.info 'no updated feeds need to be processed.'
    else
      # TODO: Child jobs
      for feed_onestop_id in updated_feed_onestop_ids
        feed = Feed.find_by(onestop_id: feed_onestop_id)
        feed_import = FeedImport.create(feed: feed)

        # Clear out old log files
        log_file_path = artifact_file_path("#{feed_onestop_id}.log")
        validation_report_path = artifact_file_path("#{feed_onestop_id}.html")
        if File.exist?(log_file_path)
          FileUtils.rm log_file_path
        end
        if File.exist?(validation_report_path)
          FileUtils.rm validation_report_path
        end
        
        # Validate and import feed
        begin
          logger.info "3. Validating feed: #{feed_onestop_id}"
          run_python('./lib/feedeater/validate.py', "--feedvalidator #{FEEDVALIDATOR} --log #{log_file_path} #{feed_onestop_id}")
          logger.info "4. Uploading feed: #{feed_onestop_id}"
          run_python('./lib/feedeater/post.py', "--log #{log_file_path} #{feed_onestop_id}")
          logger.info "5. Creating GTFS artifact: #{feed_onestop_id}"
          run_python('./lib/feedeater/artifact.py', "--log #{log_file_path} #{feed_onestop_id}")
          # TODO: upload GTFS artifact to S3
        rescue Exception => e
          # NOTE: we're catching all exceptions, including Interrupt, SignalException, and SyntaxError
          exception_log = "\n#{e}\n#{e.backtrace}\n"
          logger.error exception_log
          feed_import.update(success: false)
          Raven.capture_exception(e) if defined?(Raven)
        else
          feed.has_been_fetched_and_imported!(on_feed_import: feed_import)
        ensure
          # Report
          if File.exist?(log_file_path)
            import_log = File.open(log_file_path, 'r').read
          else
            import_log = ''
          end
          if exception_log.present?
            import_log << exception_log
          end
          if File.exist?(validation_report_path)
            validation_report = File.open(validation_report_path, 'r').read
          else
            validation_report = nil
          end
          feed_import.update(
            import_log: import_log,
            validation_report: validation_report
          )
        end
      end
    end
  end

  private

  def run_python(file, args)
    success = system("#{PYTHON} #{file} #{args}")
    raise "Error running Python #{file} #{args}" if !success
  end

  def artifact_file_path(name)
    File.join(Figaro.env.transitland_feed_data_path, name)
  end
end
