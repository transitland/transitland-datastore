class GTFSValidationService
  include Singleton

  GOOGLE_VALIDATOR_PATH = './virtualenv/bin/feedvalidator.py'
  CONVEYAL_VALIDATOR_PATH = './lib/conveyal-gtfs-lib/gtfs-lib.jar'

  def self.run_conveyal_validator(filename)
    f = nil
    Dir.mktmpdir("gtfs", Figaro.env.gtfs_tmpdir_basepath) do |dir|
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
    Dir.mktmpdir("gtfs", Figaro.env.gtfs_tmpdir_basepath) do |dir|
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

  def self.create_google_validation(feed_version)
    begin
      gtfs_filename = feed_version.file.local_path_copying_locally_if_needed
      outfile = run_google_validator(gtfs_filename)
      if outfile
        feed_version.update!(file_feedvalidator: outfile)
      else
        fail StandardError.new('No output')
      end
    rescue StandardError => e
      # TODO: Create a record to mark failure
    ensure
      feed_version.file.remove_any_local_cached_copies
    end
  end

  def self.create_feed_version_info_conveyal_validation(feed_version)
    feed_version_info = nil
    begin
      gtfs_filename = feed_version.file.local_path_copying_locally_if_needed
      outfile = run_conveyal_validator(gtfs_filename)
      if outfile
        data = outfile.read
        feed_version.feed_version_infos.where(type: 'FeedVersionInfoConveyalValidation').delete_all
        feed_version_info = feed_version.feed_version_infos.create!(type: 'FeedVersionInfoConveyalValidation', data: data)
      else
        fail StandardError.new('No output')
      end
    rescue StandardError => e
      feed_version_info = feed_version.feed_version_infos.create!(type: 'FeedVersionInfoConveyalValidation', data: {error: e.message})
    ensure
      feed_version.file.remove_any_local_cached_copies
    end
    feed_version_info
  end

  def self.run_validators(feed_version)
    # Run Conveyal Validator
    if Figaro.env.run_conveyal_validator.presence == 'true'
      create_feed_version_info_conveyal_validation(feed_version)
    end
    # Run Google Validator
    if Figaro.env.run_google_validator.presence == 'true'
      create_google_validation(feed_version)
    end
    # Return
    feed_version
  end
end
