task :import_from_gtfs, [:gtfs_file_name] => [:environment] do |t, args|
  import_from_gtfs = ImportFromGtfs.new(args[:gtfs_file_name])
  stop_count = import_from_gtfs.gtfs.stops.count
  agency_names = import_from_gtfs.gtfs.agencies.map(&:name).join(', ')
  puts "Importing #{stop_count} stops for #{agency_names}"
  stops_progress_bar = ProgressBar.new(stop_count)
  import_from_gtfs.import do
    stops_progress_bar.increment!
  end
end
