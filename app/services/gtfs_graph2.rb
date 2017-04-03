class GTFSGraph2
  class Error < StandardError
  end

  attr_accessor :feed, :feed_version

  CHANGE_PAYLOAD_MAX_ENTITIES = Figaro.env.feed_eater_change_payload_max_entities.try(:to_i) || 1_000
  STOP_TIMES_MAX_LOAD = Figaro.env.feed_eater_stop_times_max_load.try(:to_i) || 100_000
  ENTITY_CLASS_MAP = {
    GTFS::Stop => Stop,
    GTFS::Route => Route,
    GTFS::Trip => RouteStopPattern
  }

  def initialize(feed, feed_version)
    # GTFS Graph / TransitLand wrapper
    @feed = feed
    @feed_version = feed_version
    @gtfs = nil
    # Log
    @log = []
    # Lookup
    @entity_tl = {}
    @onestop_tl = {}
  end


  def load_graph
    @gtfs = @feed_version.open_gtfs
    @gtfs.load_graph
    @gtfs.load_shapes
    @gtfs.load_service_periods

    # gtfs_agency_id => operator
    oifs = Hash[@feed.operators_in_feed.map { |oif| [oif.gtfs_agency_id, oif.operator] }]

    # Operators
    @gtfs.agencies.each do |gtfs_agency|
      log "GTFS_AGENCY: #{gtfs_agency.agency_id}"
      tl_operator = oifs[gtfs_agency.agency_id]
      next unless tl_operator

      # Routes
      gtfs_agency.routes.each do |gtfs_route|
        log "\tGTFS_ROUTE: #{gtfs_route.route_id}"

        # Trips: Pass 1: Create Stops
        tl_route_stops = []
        tl_trip_stops = {}
        gtfs_route.trips.each do |gtfs_trip|
          log "\t\tGTFS_TRIP: #{gtfs_trip.trip_id}"
          tl_trip_stops[gtfs_trip] = []
          # Stops
          gtfs_trip.stops.each do |gtfs_stop|
            log "\t\t\tGTFS_STOP: #{gtfs_stop.stop_id}"
            tl_stop = find_or_initialize_stop(gtfs_stop, operator_timezone: tl_operator.timezone)
            tl_route_stops << tl_stop
            tl_trip_stops[gtfs_trip] << tl_stop
          end
        end

        # Create Route
        tl_route = find_or_initialize_route(gtfs_route, serves: tl_route_stops.uniq, operated_by: tl_operator)

        # Trips: Pass 2: Create RSPs
        tl_route_rsps = Set.new
        gtfs_route.trips.each do |gtfs_trip|
          tl_rsp = find_or_initialize_rsp(gtfs_trip, serves: tl_trip_stops[gtfs_trip], traversed_by: tl_route)
          calculate_rsp_distances(tl_rsp) # TODO
          tl_route_rsps << tl_rsp
        end

        # Update Route geometry
        representative_rsps = Route.representative_geometry(tl_route, tl_route_rsps)
        Route.geometry_from_rsps(tl_route, representative_rsps)
      end
    end
  end

  def create_changeset
    entities = @entity_tl.values.to_set
    # Convert associations
    entities.each do |tl_entity|
      if tl_entity.instance_of?(StopPlatform)
        tl_entity.parent_stop_onestop_id = tl_entity.parent_stop.onestop_id
      elsif tl_entity.instance_of?(Route)
        tl_entity.serves = tl_entity.serves.map(&:onestop_id).uniq
        tl_entity.operated_by = tl_entity.operated_by.onestop_id
      elsif tl_entity.instance_of?(Operator)
        tl_entity.serves = tl_entity.serves.map(&:onestop_id).uniq
      elsif tl_entity.instance_of?(RouteStopPattern)
        tl_entity.traversed_by = tl_entity.traversed_by.onestop_id
      end
    end

    # Changeset
    changeset = Changeset.create!(
      imported_from_feed: @feed,
      imported_from_feed_version: @feed_version
    )
    changeset.create_change_payloads(entities)
    changeset
  end

  # Compatibility
  def import_log
    @log.join("\n")
  end

  def cleanup
    @feed_version.delete_schedule_stop_pairs!
  end

  def create_change_osr
    load_graph
    changeset = create_changeset
    changeset.apply!
  end

  def ssp_schedule_async
    # pass
  end

  def ssp_perform_async(gtfs_trip_ids, agency_map, route_map, stop_map, rsp_map)
    # pass
  end

  private

  def log(msg)
    puts msg
  end

  def find_by_eiff(gtfs_entity)
    eiff = EntityImportedFromFeed.find_by(
      feed_version: @feed.active_feed_version,
      entity_type: ENTITY_CLASS_MAP[gtfs_entity.class],
      gtfs_id: gtfs_entity.id
    )
    return unless eiff
    return unless eiff.entity
    return eiff.entity
  end

  def add_eiff(tl_entity, gtfs_entity)
    tl_entity.add_imported_from_feeds ||= []
    tl_entity.add_imported_from_feeds << {feedVersion: @feed_version.sha1, gtfsId: gtfs_entity.id}
  end

  def find_or_initialize_stop(gtfs_entity, operator_timezone: nil)
    # Check cache
    tl_entity = @entity_tl[gtfs_entity]
    if tl_entity
      # log "FOUND: #{tl_entity}"
      return tl_entity
    end

    # Create
    tl_entity = find_by_eiff(gtfs_entity)
    if tl_entity
      # log "FOUND EIFF: #{tl_entity}"
    elsif gtfs_entity.parent_station.present?
      tl_entity = StopPlatform.new
      tl_entity.parent_stop = find_or_initialize_stop(@gtfs.stop(gtfs_entity.parent_station), operator_timezone: operator_timezone)
      log "NEW: #{tl_entity}"
    else
      tl_entity = Stop.new
      log "NEW: #{tl_entity}"
    end

    # Update
    tl_entity.geometry = Stop::GEOFACTORY.point(*gtfs_entity.coordinates)
    tl_entity.name = gtfs_entity.stop_name
    tl_entity.wheelchair_boarding = nil
    tl_entity.timezone = gtfs_entity.stop_timezone || operator_timezone
    tl_entity.tags = {
      stop_desc: gtfs_entity.stop_desc,
      stop_url: gtfs_entity.stop_url,
      zone_id: gtfs_entity.zone_id
    }

    # Update cache
    tl_entity.onestop_id = tl_entity.generate_onestop_id
    tl_entity = @onestop_tl[tl_entity.onestop_id] || tl_entity
    @onestop_tl[tl_entity.onestop_id] = tl_entity
    @entity_tl[gtfs_entity] = tl_entity

    # Update eiff
    add_eiff(tl_entity, gtfs_entity)

    # Return entity
    tl_entity
  end

  def find_or_initialize_route(gtfs_entity, serves: [], operated_by: nil)
    # Check cache
    tl_entity = @entity_tl[gtfs_entity]
    if tl_entity
      # log "FOUND: #{tl_entity}"
      return tl_entity
    end

    # Create
    tl_entity = find_by_eiff(gtfs_entity)
    if tl_entity
      # log "FOUND EIFF: #{tl_entity}"
    else
      tl_entity = Route.new
      log "NEW: #{tl_entity}"
    end

    # Update
    tl_entity.geometry = nil # TODO
    tl_entity.name = [gtfs_entity.route_short_name, gtfs_entity.route_long_name, gtfs_entity.id, "unknown"].select(&:present?).first
    tl_entity.vehicle_type = gtfs_entity.route_type.to_i
    tl_entity.color = Route.color_from_gtfs(gtfs_entity.route_color)
    tl_entity.tags = {
      route_long_name: gtfs_entity.route_long_name,
      route_desc: gtfs_entity.route_desc,
      route_url: gtfs_entity.route_url,
      route_color: gtfs_entity.route_color,
      route_text_color: gtfs_entity.route_text_color
    }
    # ... trips
    gtfs_trips = gtfs_entity.trips
    tl_entity.wheelchair_accessible = :unknown # TODO
    tl_entity.bikes_allowed = :unknown # TODO

    # Relations
    tl_entity.operated_by = operated_by
    tl_entity.serves = serves

    # Update cache
    tl_entity.onestop_id = tl_entity.generate_onestop_id
    tl_entity = @onestop_tl[tl_entity.onestop_id] || tl_entity
    @onestop_tl[tl_entity.onestop_id] = tl_entity
    @entity_tl[gtfs_entity] = tl_entity

    # Update eiff
    add_eiff(tl_entity, gtfs_entity)

    # Return entity
    tl_entity
  end

  def find_or_initialize_rsp(gtfs_entity, serves: [], traversed_by: nil)
    # Check cache
    stop_distances = []
    shape_line = @gtfs.shape_line(gtfs_entity.shape_id)
    shape_points = serves.map(&:coordinates)
    geometry = RouteStopPattern.line_string(RouteStopPattern.set_precision(shape_line || shape_points))
    rsp_key = [geometry, serves]
    tl_entity = @entity_tl[rsp_key]
    if tl_entity
      # log "FOUND: #{tl_entity}"
      return tl_entity
    end

    # Create
    tl_entity = find_by_eiff(gtfs_entity)
    if tl_entity
      # log "FOUND EIFF: #{tl_entity}"
    else
      tl_entity = RouteStopPattern.new
      log "NEW: #{tl_entity}"
    end

    # Update
    tl_entity.stop_distances = [0.0]*serves.size
    tl_entity.geometry = geometry
    if !shape_line.nil?
      tl_entity.geometry_source = shape_line.shape_dist_traveled.all? ? :shapes_txt_with_dist_traveled : :shapes_txt
    else
      tl_entity.geometry_source = :trip_stop_points
    end
    tl_entity.tags = {}

    # Relations
    tl_entity.serves = serves
    tl_entity.stop_pattern = serves.map(&:onestop_id)
    tl_entity.traversed_by = traversed_by

    # Update cache
    tl_entity.onestop_id = tl_entity.generate_onestop_id
    tl_entity = @onestop_tl[tl_entity.onestop_id] || tl_entity
    @onestop_tl[tl_entity.onestop_id] = tl_entity
    @entity_tl[gtfs_entity] = tl_entity
    @entity_tl[rsp_key] = tl_entity

    # Update eiff
    add_eiff(tl_entity, gtfs_entity)

    # Return entity
    tl_entity
  end

  def calculate_rsp_distances(rsp)
    # TODO: MOVE
    stops = rsp.serves
    begin
      # edited rsps will probably have a shape
      if (rsp.geometry_source.eql?(:shapes_txt_with_dist_traveled))
        # do nothing
      elsif (rsp.geometry_source.eql?(:trip_stop_points) && rsp.edited_attributes.empty?)
        rsp.fallback_distances(stops=stops)
      elsif (rsp.stop_distances.compact.empty? || rsp.issues.map(&:issue_type).include?(:distance_calculation_inaccurate))
        # avoid writing over stop distances computed with shape_dist_traveled, or already computed somehow -
        # unless if rsps have inaccurate stop distances, we'll allow a recomputation if there's a fix in place.
        rsp.calculate_distances(stops=stops)
      end
    rescue StandardError
      log "Could not calculate distances for Route Stop Pattern: #{rsp.onestop_id}"
      rsp.fallback_distances(stops=stops)
    end
  end
end
