require 'memory_profiler'
namespace :profile do
  task test: :environment do
    report = MemoryProfiler.report(allow_files: 'app') do
      feed = Feed.where(onestop_id: 'f-dr5r7-nycdotsiferry').first
      feed_version = FeedVersion.where(sha1: '55cb4f102021db7ab4ffd74b8a734e9c386cf544').first
      graph = GTFSGraph.new(feed, feed_version)
      graph.cleanup
      graph.create_change_osr
    end
    report.pretty_print(to_file: "profile_log_#{Time.new.to_i}.log")
  end
end
