class FeedValidationService
  include Singleton

  FEEDVALIDATOR_PATH = './virtualenv/bin/feedvalidator.py'

  def self.run_google_feedvalidator(filename)
    # Create a tempfile to use the filename.
    outfile = nil
    Tempfile.open(['feedvalidator', '.html']) do |tmpfile|
      outfile = tmpfile.path
    end

    # Run feedvalidator
    feedvalidator_output = nil
    IO.popen([FEEDVALIDATOR_PATH, '-n', '-o', outfile, filename], "w+") do |io|
      io.write("\n")
      io.close_write
      feedvalidator_output = io.read
    end
    # feedvalidator_output

    return unless File.exists?(outfile)
    # Unlink temporary file
    file_feedvalidator = File.open(outfile)
    File.unlink(outfile)
    file_feedvalidator
  end

  def self.run_validators(feed_version)
    # Copy file
    gtfs_filename = feed_version.file.local_path_copying_locally_if_needed
    fail Exception.new('FeedVersion has no file attachment') unless gtfs_filename

    # Run validators
    file_feedvalidator = run_google_feedvalidator(gtfs_filename)

    # Cleanup
    feed_version.file.remove_any_local_cached_copies

    # Save
    feed_version.update!(
      file_feedvalidator: file_feedvalidator,
    )

    # Return
    feed_version
  end
end
