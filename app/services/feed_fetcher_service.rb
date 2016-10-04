class FeedFetcherService
  include Singleton

  REFETCH_WAIT = 24.hours
  SPLIT_REFETCH_INTO_GROUPS = 48 # and only refetch the first group

  def self.fetch_this_feed_now(feed)
    sync_fetch_and_return_feed_versions([feed])
  end

  def self.fetch_these_feeds_now(feeds)
    sync_fetch_and_return_feed_versions(feeds)
  end

  def self.fetch_this_feed_async(feed)
    async_enqueue_and_return_workers([feed])
  end

  def self.fetch_these_feeds_async(feeds)
    async_enqueue_and_return_workers(feeds)
  end

  def self.fetch_all_feeds_async
    feeds = Feed.where('')
    async_enqueue_and_return_workers(feeds)
  end

  def self.fetch_some_ready_feeds_async(since: REFETCH_WAIT.ago, split: SPLIT_REFETCH_INTO_GROUPS)
    feed_groups = Feed.where{
      (last_fetched_at == nil) | (last_fetched_at <= since)
    }.order(last_fetched_at: :asc).in_groups(split)
    async_enqueue_and_return_workers(feed_groups.first.compact) # only the first group
  end

  def self.fetch_and_return_feed_version(feed)
    # Check Feed URL for new files.
    fetch_exception_log = nil
    feed_version = nil
    log "Fetching feed #{feed.onestop_id} from #{feed.url}"
    # Try to fetch and normalize feed; log error
    begin
      feed_version = fetch_and_normalize_feed_version(feed)
    rescue GTFS::InvalidSourceException => e
      fetch_exception_log = e.message
      if e.backtrace.present?
        fetch_exception_log << "\n"
        fetch_exception_log << e.backtrace.join("\n")
      end
      log fetch_exception_log, level=:error
    ensure
      feed.update(
        latest_fetch_exception_log: fetch_exception_log,
        last_fetched_at: DateTime.now
      )
    end
    # Return if there was not a successful fetch.
    return unless feed_version
    return unless feed_version.valid?
    if feed_version.persisted?
      log "File downloaded from #{feed.url} has an existing sha1 hash: #{feed_version.sha1}"
    else
      log "File downloaded from #{feed.url} has a new sha1 hash: #{feed_version.sha1}"
      feed_version.save!
    end
    # Return found/created FeedVersion
    feed_version
  end

  def self.url_fragment(url)
    (url || "").partition("#").last.presence
  end

  def self.fetch_and_normalize_feed_version(feed)
    gtfs = GTFS::Source.build(
      feed.url,
      strict: false,
      tmpdir_basepath: Figaro.env.gtfs_tmpdir_basepath.presence
    )
    # Normalize
    gtfs_file = nil
    gtfs_file_raw = nil
    sha1 = nil
    if self.url_fragment(feed.url)
      # Get temporary path; deletes after block
      Dir.mktmpdir do |dir|
        tmp_file_path = File.join(dir, 'normalized.zip')
        # Create normalize archive
        gtfs.create_archive(tmp_file_path)
        gtfs_file = File.open(tmp_file_path)
        gtfs_file_raw = File.open(gtfs.archive)
        sha1 = Digest::SHA1.file(tmp_file_path).hexdigest
      end
    else
      gtfs_file = File.open(gtfs.archive)
      sha1 = Digest::SHA1.file(gtfs_file).hexdigest
    end
    # Create a new FeedVersion
    feed_version = FeedVersion.find_by(sha1: sha1)
    if !feed_version
      data = {
        feed: feed,
        url: feed.url,
        file: gtfs_file,
        file_raw: gtfs_file_raw,
        fetched_at: DateTime.now
      }
      data = data.merge!(read_gtfs_info(gtfs))
      feed_version = FeedVersion.new(data)
    end
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
        feed_id:             feed_info.feed_id
      })
    end
    return {
      earliest_calendar_date: earliest_calendar_date,
      latest_calendar_date: latest_calendar_date,
      tags: tags
    }
  end

  private

    def self.sync_fetch_and_return_feed_versions(feeds)
      feeds.map do |feed|
        self.fetch_and_return_feed_version(feed)
      end
    end

    def self.async_enqueue_and_return_workers(feeds)
      feeds.map do |feed|
        FeedFetcherWorker.perform_async(feed.onestop_id)
      end
    end

end
