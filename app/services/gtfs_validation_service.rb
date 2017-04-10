class GTFSValidationService
  include Singleton

  GOOGLE_VALIDATOR_PATH = './virtualenv/bin/feedvalidator.py'
  CONVEYAL_VALIDATOR_PATH = './lib/conveyal-gtfs-lib/gtfs-lib.jar'

  def self.run_conveyal_validator(filename)
    outfile = nil
    Tempfile.open(['conveyal', '.json']) do |tmpfile|
    outfile = tmpfile.path
    end

    # Run feedvalidator
    output = nil
    IO.popen(['java', '-Xmx6G', '-jar', CONVEYAL_VALIDATOR_PATH, '-validate', filename, outfile], "w+") do |io|
      io.write("\n")
      io.close_write
      output = io.read
    end

    return unless File.exists?(outfile)
    # Unlink temporary file
    f = File.open(outfile)
    File.unlink(outfile)
    f
  end

  def self.run_google_validator(filename)
    # Create a tempfile to use the filename.
    outfile = nil
    Tempfile.open(['feedvalidator', '.html']) do |tmpfile|
      outfile = tmpfile.path
    end

    # Run feedvalidator
    feedvalidator_output = nil
    IO.popen([GOOGLE_VALIDATOR_PATH, '-n', '-o', outfile, filename], "w+") do |io|
      io.write("\n")
      io.close_write
      feedvalidator_output = io.read
    end
    # feedvalidator_output

    return unless File.exists?(outfile)
    # Unlink temporary file
    f = File.open(outfile)
    File.unlink(outfile)
    f
  end

  def self.run_validators(feed_version)
    # Copy file
    gtfs_filename = feed_version.file.local_path_copying_locally_if_needed
    fail Exception.new('FeedVersion has no file attachment') unless gtfs_filename

    # Run validators
    if Figaro.env.run_google_validator.presence == 'true'
      outfile = run_google_validator(gtfs_filename)
      if outfile
        feed_version.update!(file_feedvalidator: outfile)
      end
    end
    if Figaro.env.run_conveyal_validator.presence == 'true'
      outfile = run_conveyal_validator(gtfs_filename)
      if outfile
        data = outfile.read
        feed_version.feed_version_infos.where(type: 'FeedVersionInfoConveyalValidation').delete_all
        feed_version.feed_version_infos.create!(type: 'FeedVersionInfoConveyalValidation', data: data)
      end
    end

    # Cleanup
    feed_version.file.remove_any_local_cached_copies

    # Return
    feed_version
  end
end
