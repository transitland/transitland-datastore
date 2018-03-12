class FeedFetcherService
  include Singleton

  REFETCH_WAIT = 24.hours
  SPLIT_REFETCH_INTO_GROUPS = 48 # and only refetch the first group

  def self.fetch_these_feeds_async(feeds)
    async_enqueue_and_return_workers(feeds)
  end

  def self.fetch_all_feeds_async
    feeds = Feed.where('')
    async_enqueue_and_return_workers(feeds)
  end

  def self.fetch_some_ready_feeds_async(since: REFETCH_WAIT.ago, split: SPLIT_REFETCH_INTO_GROUPS)
    batch = Set.new
    Feed.where{
      (last_fetched_at == nil) | (last_fetched_at <= since)
    }.order(last_fetched_at: :asc).each { |feed| 
      next if feed.status != 'active'
      next if feed.import_policy == 'manual'
      batch << feed
      break if batch.size >= split
    }
    async_enqueue_and_return_workers(batch)
  end

  def self.fetch_and_return_feed_version(feed)
    # Check fetch policy
    fetch_policy = feed.status
    if fetch_policy != 'active'
      log "Feed #{feed.onestop_id} not fetched, policy is: #{fetch_policy}"
      return
    end
    # Check Feed URL for new files.
    fetch_exception_log = nil
    feed_version = nil
    log "Fetching feed #{feed.onestop_id} from #{feed.url}"
    # Try to fetch and normalize feed; log error
    error_handler = Proc.new { |e, issue_type|
      fetch_exception_log = e.message
      if e.backtrace.present?
        fetch_exception_log << "\n"
        fetch_exception_log << e.backtrace.join("\n")
      end
      log fetch_exception_log, level=:error
      Issue.create!(issue_type: issue_type, details: fetch_exception_log)
        .entities_with_issues.create!(entity: feed, entity_attribute: "url")
    }
    begin
      Issue.issues_of_entity(feed, entity_attributes: ["url"]).each(&:deprecate)
      feed_version = fetch_normalize_validate_create(feed, url: feed.url)
    rescue GTFS::InvalidURLException => e
      error_handler.call(e, 'feed_fetch_invalid_url')
    rescue GTFS::InvalidResponseException => e
      error_handler.call(e, 'feed_fetch_invalid_response')
    rescue GTFS::InvalidZipException => e
      error_handler.call(e, 'feed_fetch_invalid_zip')
    rescue GTFS::InvalidSourceException => e
      error_handler.call(e, 'feed_fetch_invalid_source')
    ensure
      feed.update(
        last_fetched_at: DateTime.now
      )
    end
    # Return if there was not a successful fetch.
    return unless feed_version
    return unless feed_version.valid?
    log "File downloaded from #{feed.url}, sha1 hash: #{feed_version.sha1}"
    # Return found/created FeedVersion
    feed_version
  end

  def self.url_fragment(url)
    (url || "").partition("#").last.presence
  end

  def self.fetch_normalize_validate_create(feed, url: url, file: nil)
    # Fetch
    gtfs = self.fetch_gtfs(url: url, file: file, ssl_verify: feed.ssl_verify)
    # Normalize
    gtfs_file_raw = self.normalize_gtfs(gtfs, url: url)
    # Validate
    self.gtfs_minimal_validation(gtfs)
    # Create
    create_feed_version(feed, url, gtfs, gtfs_file_raw: gtfs_file_raw)
  end

  def self.fetch_gtfs(url: nil, file: nil, ssl_verify: nil)
    # System-wide ssl_verify
    if Figaro.env.feed_fetcher_ssl_verify.presence == 'false'
      ssl_verify = false
    end
    # Open GTFS
    GTFS::Source.build(
      file || url,
      strict: false,
      auto_detect_root: true,
      ssl_verify: ssl_verify,
      tmpdir_basepath: Figaro.env.gtfs_tmpdir_basepath.presence
    )
  end

  def self.normalize_gtfs(gtfs, url: nil)
    # Update gtfs.archive path and return original path
    gtfs_file_raw = nil
    if self.url_fragment(url)
      tmp_file_path = File.join(gtfs.path, 'normalized.zip')
      gtfs.create_archive(tmp_file_path)
      gtfs_file = tmp_file_path
      gtfs_file_raw = gtfs.archive
      gtfs.archive = tmp_file_path
    end
    gtfs_file_raw
  end

  def self.create_feed_version(feed, url, gtfs, gtfs_file_raw: nil)
    # Create sha1
    gtfs_file = gtfs.archive
    sha1 = Digest::SHA1.file(gtfs_file).hexdigest

    # Check if FeedVersion exists
    feed_version = FeedVersion.find_by(sha1: sha1)
    return feed_version if feed_version # already exists

    # Create the FeedVersion
    # Note: this is not atomic & the constraint is in the model, not index
    data = {
      sha1: sha1,
      feed: feed,
      url: url,
      fetched_at: DateTime.now,
    }
    data = data.merge!(read_gtfs_info(gtfs))
    feed_version = FeedVersion.create!(data)

    # Upload files
    upload = {
      file: File.open(gtfs_file),
      file_raw: (File.open(gtfs_file_raw) if gtfs_file_raw),
    }
    feed_version.update!(upload)

    # Enqueue validators
    GTFSGoogleValidationWorker.perform_async(feed_version.sha1)
    GTFSConveyalValidationWorker.perform_async(feed_version.sha1)
    GTFSStatisticsWorker.perform_async(feed_version.sha1)

    # Return the found or created feed_version
    feed_version
  end

  def self.read_gtfs_info(gtfs)
    start_date, end_date = gtfs.service_period_range
    earliest_calendar_date = start_date
    latest_calendar_date = end_date
    tags = {}
    if gtfs.file_present?('feed_info.txt') && gtfs.feed_infos.count > 0
      feed_info = gtfs.feed_infos[0]
      tags.merge!({
        feed_publisher_name: feed_info.feed_publisher_name,
        feed_publisher_url:  feed_info.feed_publisher_url,
        feed_lang:           feed_info.feed_lang,
        feed_start_date:     feed_info.feed_start_date,
        feed_end_date:       feed_info.feed_end_date,
        feed_version:        feed_info.feed_version,
        feed_id:             feed_info.feed_id,
        feed_contact_email:  feed_info.feed_contact_email,
        feed_contact_url:    feed_info.feed_contact_url
      })
    end
    return {
      earliest_calendar_date: earliest_calendar_date,
      latest_calendar_date: latest_calendar_date,
      tags: tags
    }
  end

  def self.gtfs_minimal_validation(gtfs)
    # Perform some basic validation!
    # Required files present
    raise GTFS::InvalidSourceException.new('missing required files') unless gtfs.valid?
    # At least 1 each: agency, stop, route, trip, stop_times
    # Read just 1 row & break
    e = []
    gtfs.each_agency { |i| e << i; break }
    gtfs.each_stop { |i| e << i; break }
    gtfs.each_route { |i| e << i; break }
    gtfs.each_trip { |i| e << i; break }
    gtfs.each_stop_time { |i| e << i; break }
    raise GTFS::InvalidSourceException.new('missing required entities') unless e.size == 5
    # calendar/calendar_dates
    a, b = gtfs.service_period_range
    raise GTFS::InvalidSourceException.new('missing calendar data') unless a && b
    # Minimal validation satisfied
    return true
  end

  private

  def self.async_enqueue_and_return_workers(feeds)
    feeds.map do |feed|
      FeedFetcherWorker.perform_async(feed.onestop_id)
    end
  end

end
