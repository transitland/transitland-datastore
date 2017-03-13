class FeedStatisticsService
  include Singleton

  def self.generate_statistics(feed_version)
    # Copy file
    gtfs_filename = feed_version.file.local_path_copying_locally_if_needed
    fail Exception.new('FeedVersion has no file attachment') unless gtfs_filename

    # Generate statistics

    # Cleanup
    feed_version.file.remove_any_local_cached_copies

    # Return
    feed_version
  end
end
