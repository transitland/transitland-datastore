ActiveRecord::Base.logger = Logger.new(STDOUT)

DEFAULT_GEOMETRY = {
  "type": "Polygon",
  "coordinates": [
    [
      [
        -121.56649700000001,
        37.00360599999999
      ],
      [
        -122.23195700000001,
        37.48541199999998
      ],
      [
        -122.38653400000001,
        37.600005999999965
      ],
      [
        -122.412018,
        37.63110599999998
      ],
      [
        -122.39432299999996,
        37.77643899999997
      ],
      [
        -121.65072100000002,
        37.12908099999998
      ],
      [
        -121.61080899999999,
        37.085774999999984
      ],
      [
        -121.56649700000001,
        37.00360599999999
      ]
    ]
  ]
}

path = ARGV[0] || File.open(Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip'))
feed_onestop_id = ARGV[1] || 'f-9q9-debug'
operator_onestop_id = ARGV[2] || 'o-9q9-debug'
gtfs_agency_id = ARGV[3] || 'caltrain-ca-us'
# import_level = (ARGV[4].presence || 1).to_i

feed = Feed.find_by_onestop_id(feed_onestop_id)
unless feed
  feed = Feed.create!(onestop_id: feed_onestop_id, url: "http://transit.land")
  operator = Operator.create!(onestop_id: operator_onestop_id, name: 'Debug', timezone: 'America/Los_Angeles', geometry: DEFAULT_GEOMETRY)
  feed.operators_in_feed.create!(operator: operator, gtfs_agency_id: gtfs_agency_id)
end

feed_version = feed.feed_versions.new(file: File.open(path))
feed_version.valid?
feed_version = FeedVersion.find_by(sha1: feed_version.sha1) || feed_version
Stop.connection
graph = GTFSGraph.new(feed, feed_version)
graph.cleanup
graph.create_change_osr
