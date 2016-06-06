ActiveRecord::Base.logger = Logger.new(STDOUT)

path = ARGV[0] || Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip')
feed_onestop_id = ARGV[2] || 'f-123-debug'

class DebugGTFSGraph < GTFSGraph
  def create_change_osr
    log "Load GTFS"
    @gtfs.load_graph
    log "Load TL"
    load_tl_stops
    load_tl_routes
    load_tl_transfers
    operators = load_tl_operators
    routes = operators.map(&:serves).reduce(Set.new, :+).map { |i| find_by_onestop_id(i) }
    stops = routes.map(&:serves).reduce(Set.new, :+).map { |i| find_by_onestop_id(i) }
    ####
    log "Create changeset"
    changeset = Changeset.create(
      imported_from_feed: @feed,
      imported_from_feed_version: @feed_version,
      notes: "Changeset created by FeedEaterWorker for #{@feed.onestop_id} #{@feed_version.sha1}"
    )
    log "Create: Operators, Stops, Routes"
    # Update Feed Bounding Box
    log "  updating feed bounding box"
    @feed.set_bounding_box_from_stops(stops)
    # FIXME: Run through changeset
    @feed.save!
    # Clear out serves; can't find routes that don't exist yet.
    operators.each { |operator| operator.serves = nil }
    log "  operators: #{operators.size}"
    begin
      changeset.create_change_payloads(operators)
      log "  stops: #{stops.size}"
      changeset.create_change_payloads(stops.partition { |i| i.type != 'StopPlatform' }.flatten)
      log "  routes: #{routes.size}"
      changeset.create_change_payloads(routes)
    rescue Changeset::Error => e
      log "Error: #{e.message}"
      log "Payload:"
      changeset.change_payloads.each do |change_payload|
        log change_payload.to_json
      end
    end
    log "Changeset apply"
    t = Time.now
    changeset.apply!
    log "  apply done: time #{Time.now - t}"
  end

  def load_tl_transfers
    @gtfs.transfers.each do |transfer|
      stop = find_by_gtfs_entity(@gtfs.stop(transfer.from_stop_id))
      to_stop = find_by_gtfs_entity(@gtfs.stop(transfer.to_stop_id))
      next unless stop && to_stop
      stop.includes_stop_transfers ||= []
      stop.includes_stop_transfers << {
        toStopOnestopId: to_stop.onestop_id,
        transferType: transfer.transfer_type,
        minTransferTime: transfer.min_transfer_time.to_i
      }
    end
  end
end


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
        geohash: '123',
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
graph = DebugGTFSGraph.new(feed, feed_version)
graph.cleanup
graph.create_change_osr
