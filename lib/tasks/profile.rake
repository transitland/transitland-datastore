begin
  require 'memory_profiler'
rescue LoadError

end

def create_feed(feed_onestop_id, path)
  feed = Feed.create!(onestop_id: feed_onestop_id, url: 'http://transit.land/example.zip', geometry: "POINT(-124.4,50.0)")
  operator = Operator.create!(onestop_id: 'o-9q9-caltrain', timezone: 'America/Los_Angeles', name: 'Caltrain', geometry: "POLYGON ((-121.56 37.0036, -122.23195 37.4854, -122.38 37.600))")
  feed.operators_in_feed.create!(operator: operator, gtfs_agency_id: 'caltrain-ca-us')
  feed
end

namespace :profile do
  task test: :environment do
    if defined?(MemoryProfiler)
      report = MemoryProfiler.report(allow_files: 'app') do
        feed_onestop_id = 'f-9q9-caltrain'
        path = Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip')
        feed = Feed.find_by_onestop_id(feed_onestop_id) || create_feed(feed_onestop_id, path)
        feed_version = feed.feed_versions.create!(file: File.open(path))
        graph = GTFSGraph.new(feed, feed_version)
        graph.cleanup
        graph.create_change_osr
      end
      report.pretty_print(to_file: "profile_log_#{Time.new.to_i}.log")
    end
  end
end
