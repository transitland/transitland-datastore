ActiveRecord::Base.logger = Logger.new(STDOUT)

path = ARGV[0] || Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip')
feed_onestop_id = ARGV[2] || 'f-9q9-debug'

feed = Feed.find_by_onestop_id(feed_onestop_id)
unless feed
  feed = Feed.create!(
    onestop_id: feed_onestop_id,
    url: "http://transit.land",
    geometry: "POINT(#{rand(-124.4..-90.1)} #{rand(28.1..50.0095)})"
  )
  GTFS::Source.build(path).agencies.each { |agency|
    operator = Operator.create!(
      onestop_id: OnestopId::OperatorOnestopId.new(
        geohash: '9q9',
        name: agency.name.presence || agency.id
      ),
      name: agency.agency_name,
      timezone: agency.agency_timezone,
      geometry: "POINT(#{rand(-124.4..-90.1)} #{rand(28.1..50.0095)})"
    )
    feed.operators_in_feed.create!(operator: operator, gtfs_agency_id: agency.id)
  }
end

feed_version = feed.feed_versions.new(file: File.open(path))
feed_version.valid?
feed_version = FeedVersion.find_by(sha1: feed_version.sha1) || feed_version
Stop.connection
graph = GTFSGraph.new(feed, feed_version)
graph.cleanup
graph.create_change_osr
