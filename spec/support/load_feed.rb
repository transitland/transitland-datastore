def load_feed(feed_version_name: nil, feed_version: nil, import_level: 1, block_before_level_1: nil, block_before_level_2: nil)
  block_before_level_1 ||= Proc.new { |graph| }
  block_before_level_2 ||= Proc.new { |graph| }
  feed_version = create(feed_version_name) if feed_version.nil?
  feed = feed_version.feed
  graph = GTFSGraph2.new(feed, feed_version)
  block_before_level_1.call(graph)
  graph.create_change_osr
  block_before_level_2.call(graph)
  if import_level >= 2
    GTFSScheduleImport.new(feed, feed_version).load_schedule
  end
  feed.activate_feed_version(feed_version.sha1, import_level)
  return feed, feed_version
end
