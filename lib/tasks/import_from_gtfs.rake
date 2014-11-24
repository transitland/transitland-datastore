require 'open-uri'

task :import_from_gtfs, [:gtfs_path] => [:environment] do |t, args|
  uri = URI.parse(args[:gtfs_path])
  if uri.scheme == 'http' || uri.scheme == 'https'
    file = Tempfile.new(['gtfs-archive', '.zip'])
    file.binmode
    begin
      open(uri, 'rb', content_length_proc: lambda {|content_length_bytes|
        if content_length_bytes && 0 < content_length_bytes
          puts "Downloading a file that is #{Filesize.from("#{content_length_bytes} B").pretty} in size."
          @pbar = ProgressBar.create(total: content_length_bytes)
        end
      }, progress_proc: lambda {|size|
        @pbar.progress = size
      }) do |downloaded_archive|
        file << downloaded_archive.read
        run_import_and_display_progress(file.path)
      end
    ensure
      file.close
      file.unlink # deletes the temp file
    end
  elsif File.file?(args[:gtfs_path])
     run_import_and_display_progress(args[:gtfs_path])
  else
     puts "You didn't specify a valid file path or URL."
  end

end

private

def run_import_and_display_progress(file_path)
  import_from_gtfs = ImportFromGtfs.new(file_path)
  stop_count = import_from_gtfs.gtfs.stops.count
  agency_names = import_from_gtfs.gtfs.agencies.map(&:name).join(', ')
  puts "Importing #{stop_count} stops for #{agency_names}"
  stops_progress_bar = ProgressBar.create(total: stop_count)
  import_from_gtfs.import do
    stops_progress_bar.increment
  end
end
