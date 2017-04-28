class GTFSValidationService
  include Singleton

  GOOGLE_VALIDATOR_PATH = './virtualenv/bin/feedvalidator.py'
  CONVEYAL_VALIDATOR_PATH = './lib/conveyal-gtfs-lib/gtfs-lib.jar'

  def self.run_conveyal_validator(filename)
    f = nil
    Dir.mktmpdir do |dir|
      # Run feedvalidator
      outfile = File.join(dir, 'conveyal.json')
      IO.popen(['java', '-Djava.io.tmpdir='+dir, '-jar', CONVEYAL_VALIDATOR_PATH, '-validate', filename, outfile], "w+") do |io|
      end
      return unless File.exists?(outfile)
      f = File.open(outfile)
    end
    f
  end

  def self.run_google_validator(filename)
    f = nil
    Dir.mktmpdir do |dir|
      # Create a tempfile to use the filename.
      outfile = File.join(dir, 'feedvalidator.html')
      # Run feedvalidator
      IO.popen({'TMP' => dir}, [GOOGLE_VALIDATOR_PATH, '-n', '-o', outfile, filename], "w+") do |io|
      end
      return unless File.exists?(outfile)
      f = File.open(outfile)
    end
    f
  end

  def self.run_validators(feed_version)
    # Copy file
    gtfs_filename = feed_version.file.local_path_copying_locally_if_needed
    fail Exception.new('FeedVersion has no file attachment') unless gtfs_filename

    # Run validators
    if Figaro.env.run_conveyal_validator.presence == 'true'
      outfile = run_conveyal_validator(gtfs_filename)
      if outfile
        data = outfile.read
        feed_version.feed_version_infos.where(type: 'FeedVersionInfoConveyalValidation').delete_all
        feed_version.feed_version_infos.create!(type: 'FeedVersionInfoConveyalValidation', data: data)
      end
    end
    # Run this second; sometimes feed_version.update! removes gtfs_filename.
    if Figaro.env.run_google_validator.presence == 'true'
      outfile = run_google_validator(gtfs_filename)
      if outfile
        feed_version.update!(file_feedvalidator: outfile)
      end
    end

    # Cleanup
    feed_version.file.remove_any_local_cached_copies

    # Return
    feed_version
  end
end
