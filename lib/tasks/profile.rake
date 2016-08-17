begin
  require 'memory_profiler'
rescue LoadError

end

create_nycdot = Proc.new {
  feed_onestop_id = 'f-dr5r7-nycdotsiferry'
  path = Rails.root.join('spec/support/example_gtfs_archives/siferry-gtfs.zip')
  feed = Feed.create!(onestop_id: feed_onestop_id, url: 'http://transit.land/example.zip', geometry: "POINT(-124.4,50.0)")
  operator = Operator.find_by_onestop_id!('o-dr5r7-nycdot') || Operator.create!(onestop_id: 'o-r5r7-nycdot', timezone: 'America/New_York', name: 'New York City Department of Transportation', geometry: "POLYGON ((-74.07221 40.6442, -74.0722 40.64412, -74.01266 40.70136, -74.072205 40.6441))")
  feed.operators_in_feed.create!(operator: operator, gtfs_agency_id: 'NYC DOT')
  feed_version = FeedVersion.where(sha1: Digest::SHA1.file(path).hexdigest).first
  unless feed_version.nil?
    feed.feed_versions << feed_version
  else
    feed_version = feed.feed_versions.create!(file: File.open(path))
  end
  [feed, feed_version]
}

create_caltrain = Proc.new {
  feed_onestop_id = 'f-9q9-caltrain'
  path = Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip')
  feed = Feed.create!(onestop_id: feed_onestop_id, url: 'http://transit.land/example.zip', geometry: "POINT(-124.4,50.0)")
  operator =  Operator.find_by_onestop_id!('o-9q9-caltrain') || Operator.create!(onestop_id: 'o-9q9-caltrain', timezone: 'America/Los_Angeles', name: 'Caltrain', geometry: "POLYGON ((-121.56 37.0036, -122.23195 37.4854, -122.38 37.600))")
  feed.operators_in_feed.create!(operator: operator, gtfs_agency_id: 'caltrain-ca-us')
  feed_version = FeedVersion.where(sha1: Digest::SHA1.file(path).hexdigest).first
  unless feed_version.nil?
    feed.feed_versions << feed_version
  else
    feed_version = feed.feed_versions.create!(file: File.open(path))
  end
  [feed, feed_version]
}

def run_and_report(feed_and_feed_version, args)
  report = MemoryProfiler.report(allow_files: 'app') do
    feed, feed_version = feed_and_feed_version.call
    graph = GTFSGraph.new(feed, feed_version)
    graph.cleanup
    graph.create_change_osr
  end
  f = "profile_log_#{Time.new.to_i}.log"
  f = File.join(args[:directory].to_s, f) if args[:directory]
  report.pretty_print(to_file: f)
end

namespace :profile do
  namespace :import do
    task :nycdot, [:directory] => [:environment] do |t, args|
      if defined?(MemoryProfiler)
        run_and_report(create_nycdot, args)
      end
    end
    task :caltrain, [:directory] => [:environment] do |t, args|
      if defined?(MemoryProfiler)
        run_and_report(create_caltrain, args)
      end
    end
  end
end
