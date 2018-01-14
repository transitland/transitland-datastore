ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::DEBUG
require 'sidekiq/testing'

path = ARGV[0] || Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip')
feed_onestop_id = ARGV[1] || 'f-123-debug'
import_level = (ARGV[2].presence || 1).to_i

OIFS = {}

def create_from_gtfs(feed_onestop_id, path)
  feed = Feed.create!(
    onestop_id: feed_onestop_id,
    url: "http://transit.land/example.zip",
    geometry: "POINT(#{rand(-124.4..-90.1)} #{rand(28.1..50.0095)})"
  )
  GTFS::Source.build(path).agencies.each { |agency|
    osid = OIFS[agency.id] || OnestopId::OperatorOnestopId.new(
      geohash: '123',
      name: agency.id.presence || agency.name.presence || 'test'
    ).to_s
    operator = Operator.find_by_onestop_id(osid) || Operator.create!(
      onestop_id: osid,
      name: agency.agency_name,
      timezone: agency.agency_timezone,
      geometry: "POINT(#{rand(-124.4..-90.1)} #{rand(28.1..50.0095)})"
    )
    feed.operators_in_feed.find_or_create_by!(operator: operator, gtfs_agency_id: agency.id)
  }
  feed
end

# Check for feed_version
sha1 = Digest::SHA1.file(path).hexdigest
feed_version = FeedVersion.find_by(sha1: sha1)
unless feed_version
  feed = Feed.find_by_onestop_id(feed_onestop_id) || create_from_gtfs(feed_onestop_id, path)
  feed_version = feed.feed_versions.create!(file: File.open(path))
end
feed_version.save!

# Run GTFSGraph
g = GTFSImporter.new(feed_version)
g.clean_start
g.import
