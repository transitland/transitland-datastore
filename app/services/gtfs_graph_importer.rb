class GTFSGraphImporter
  class Error < StandardError
  end

  attr_accessor :feed, :feed_version

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
    @indent = 0
    # Lookup
    @entity_tl = {}
    @onestop_tl = {}
  end

  def load_graph
    @gtfs = @feed_version.open_gtfs
    @gtfs.load_graph
    @gtfs.load_shapes
    @gtfs.load_service_periods

    # Find all platforms & entrances for each station
    @station_children = Hash.new { |h,k| h[k] = Set.new }
    @gtfs.stops.each do |stop|
      station = @gtfs.stop(stop.parent_station)
      @station_children[station] << stop if station
    end

    # gtfs_agency_id => operator
    oifs = Hash[@feed.operators_in_feed.map { |oif| [oif.gtfs_agency_id, oif.operator] }]

    # Operators
    @gtfs.agencies.each do |gtfs_agency|
      info("GTFS Agency: #{gtfs_agency.agency_id}", indent: 1)
      tl_operator = oifs[gtfs_agency.agency_id]
      if !tl_operator
        info("Operator not found, skipping", indent: 2)
        next
      end
      info("Operator: #{tl_operator.onestop_id}", indent: 2)
      @entity_tl[gtfs_agency] = tl_operator
      add_eiff(tl_operator, gtfs_agency)

      # Routes
      gtfs_agency.routes.each do |gtfs_route|
        t0 = Time.now
        info("GTFS Route: #{gtfs_route.route_id}", indent: 2)
        if gtfs_route.trips.empty?
          info("Contains no trips, skipping", indent: 3)
          next
        end
        info("Processing Trips...", indent: 3)

        # Trips: Pass 1: Create Stops
        tl_route_serves = Set.new
        tl_trip_stop_sequence = {}
        gtfs_route.trips.each do |gtfs_trip|
          # info("GTFS Trip: #{gtfs_trip.trip_id}", indent: 3)
          tl_trip_stop_sequence[gtfs_trip] = []
          gtfs_trip.stop_sequence.each do |gtfs_stop|
            parent_station = @gtfs.stop(gtfs_stop.parent_station)
            find_or_initialize_station(parent_station, operated_by: tl_operator) if parent_station
            tl_stop = find_or_initialize_stop(gtfs_stop, operated_by: tl_operator)
            tl_route_serves << tl_stop
            tl_trip_stop_sequence[gtfs_trip] << tl_stop
          end
        end

        # Create Route
        if tl_route_serves.empty?
          info("Contains no stops, skipping", indent: 3)
          next
        end
        info("Processing Route...", indent: 3)

        tl_route = find_or_initialize_route(gtfs_route, serves: tl_route_serves, operated_by: tl_operator)

        # Trips: Pass 2: Create RSPs
        info("Processing RouteStopPatterns...", indent: 3)
        tl_route_rsps = Set.new
        gtfs_route.trips.each do |gtfs_trip|
          next unless gtfs_trip.stop_sequence.size > 1
          tl_rsp = find_or_initialize_rsp(gtfs_trip, serves: tl_trip_stop_sequence[gtfs_trip], traversed_by: tl_route)
          tl_route_rsps << tl_rsp
        end

        # Update Route geometry
        info("Processing representative geometries...", indent: 3)
        representative_rsps = Route.representative_geometry(tl_route, tl_route_rsps)
        Route.geometry_from_rsps(tl_route, representative_rsps)

        # Log
        info("Time: #{Time.now - t0}", indent: 3)
        info("Route: #{tl_route.onestop_id}", indent: 3)
        info("Stops: #{tl_route_serves.size}", indent: 3)
        tl_route_serves.each { |i| info(i.onestop_id, indent: 4)}
        info("RouteStopPatterns: #{tl_route_rsps.size}", indent: 3)
        tl_route_rsps.each { |i| info(i.onestop_id, indent: 4)}
      end
    end

    # Load transfers
    if @gtfs.file_present?('transfers.txt')
      @gtfs.transfers.each do |transfer|
        stop = @entity_tl[@gtfs.stop(transfer.from_stop_id)]
        to_stop = @entity_tl[@gtfs.stop(transfer.to_stop_id)]
        next unless stop && to_stop
        stop.includes_stop_transfers ||= Set.new
        stop.includes_stop_transfers << {
          toStopOnestopId: to_stop.onestop_id,
          transferType: StopTransfer::GTFS_TRANSFER_TYPE[transfer.transfer_type.presence || "0"],
          minTransferTime: transfer.min_transfer_time.to_i
        }
      end
    end

  end

  def create_changeset
    # Convert associations
    entities = @entity_tl.values.to_set
    entities.each do |tl_entity|
      if tl_entity.instance_of?(StopPlatform) || tl_entity.instance_of?(StopEgress)
        tl_entity.parent_stop_onestop_id = tl_entity.parent_stop.onestop_id
      elsif tl_entity.instance_of?(Route)
        tl_entity.serves = tl_entity.serves.map(&:onestop_id).uniq
        tl_entity.operated_by = tl_entity.operated_by.onestop_id
      elsif tl_entity.instance_of?(RouteStopPattern)
        tl_entity.traversed_by = tl_entity.traversed_by.onestop_id
      end
    end

    # Changeset
    changeset = Changeset.create!(
      imported_from_feed: @feed,
      imported_from_feed_version: @feed_version
    )
    begin
      changeset.create_change_payloads(entities)
    rescue Changeset::Error => e
      info("Changeset Error: #{e}")
      info("Payload:")
      info(e.payload.to_json.to_s)
      raise e
    rescue StandardError => e
      info("Error: #{e}")
      raise e
    end
    changeset
  end

  # Compatibility
  def import_log
    @log.join("\n")
  end

  def create_change_osr
    private_create_change_osr
  end

  def cleanup
    @feed_version.delete_schedule_stop_pairs!
  end

  def ssp_schedule_async
    @gtfs.trip_id_chunks(1_000_000) do |trip_ids|
      yield trip_ids, nil, nil, nil, nil
    end
  end

  private

  def info(msg, indent: nil, plus: 0)
    @indent = indent if indent
    msg = ("\t"*@indent) + ("\t"*plus) + msg
    @log << msg
    log(msg)
  end

  def debug(msg, indent: nil, plus: 0)
    @indent = indent if indent
    msg = ("\t"*@indent) + ("\t"*plus) + msg
    log(msg)
  end

  def private_create_change_osr
    ##### Backwards compat #####
    info("GTFSGraphImporter: #{@feed.onestop_id} #{@feed_version.sha1}", indent: 0)

    load_graph
    entities = @entity_tl.values.to_set

    # Create FeedVersion issue and fail if no matching operators found.
    info("Comparing agencies", indent: 0)
    Issue.where(issue_type: 'feed_import_no_operators_found').issues_of_entity(feed_version).each(&:deprecate)
    # ... create new issue
    if @entity_tl.size == 0
      # Describe all the rows in 'agency.txt':
      details = ["No Agency in the GTFS Feed had a matching Transitland Operator"]
      details << "Agencies in GTFS Feed:"
      @gtfs.agencies.each { |agency| details << "\t#{agency.agency_id}: #{agency.agency_name}"}
      # Describe all Operators in Feed records:
      details << "Existing Feed agency_id <-> Transitland Operator associations:"
      @feed.operators_in_feed.each { |oif| details << "\t#{oif.gtfs_agency_id}: #{oif.operator.onestop_id}" }
      # Create Issue
      issue = Issue.new(issue_type: 'feed_import_no_operators_found', details: details.join("\n"))
      issue.entities_with_issues.new(entity: @feed_version)
      issue.save!
      fail GTFSGraphImporter::Error.new('No agencies found that match operators_in_feed')
    end

    # Update Feed Geometry
    info("Updating Feed geometry", indent: 0)
    @feed.set_bounding_box_from_stops(entities.select { |i| i.is_a?(Stop) })
    @feed.save!

    # Create changeset
    info("Changeset create", indent: 0)
    changeset = create_changeset

    # Delete old RSPs
    info("Checking for old RSPs", indent: 0)
    feed_rsps = Set.new(@feed.imported_route_stop_patterns.where("edited_attributes='{}'").pluck(:onestop_id))
    rsps_to_remove = feed_rsps - Set.new(entities.select { |i| i.is_a?(RouteStopPattern)}.map(&:onestop_id))
    if rsps_to_remove.size > 0
      changeset.change_payloads.create!(payload: {
        changes: rsps_to_remove.map {|i| {action: "destroy", routeStopPattern: {onestopId: i}}}
      })
    end

    # Apply changeset
    info("Changeset apply", indent: 0)
    t = Time.now
    changeset.apply!
    info("Changeset apply done! Time: #{Time.now - t}", indent: 0)
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
    # TODO: use simple set; convert to changeset format at end.
    tl_entity.add_imported_from_feeds ||= Set.new
    tl_entity.add_imported_from_feeds << {feedVersion: @feed_version.sha1, gtfsId: gtfs_entity.id}
  end

  def find_or_initialize(gtfs_entity, key: nil, **kwargs)
    # Check cache
    key ||= gtfs_entity
    tl_entity = @entity_tl[key]
    if tl_entity
      add_eiff(tl_entity, gtfs_entity)
      # debug("#{tl_entity.class.name} cached: #{gtfs_entity.id} -> #{tl_entity.onestop_id}", plus: 1)
      return tl_entity
    end

    tl_entity = find_by_eiff(gtfs_entity)

    # Create / Update
    tl_entity = yield(tl_entity)

    # Cache
    tl_entity.onestop_id ||= tl_entity.generate_onestop_id
    tl_entity = @onestop_tl[tl_entity.onestop_id] || tl_entity
    @onestop_tl[tl_entity.onestop_id] = tl_entity
    @entity_tl[key] = tl_entity
    add_eiff(tl_entity, gtfs_entity)

    # Debug
    if tl_entity.persisted?
      debug("#{tl_entity.class.name} eiff: #{gtfs_entity.id} -> #{tl_entity.onestop_id}", plus: 1)
    else
      debug("#{tl_entity.class.name} new: #{gtfs_entity.id} -> #{tl_entity.onestop_id}", plus: 1)
    end

    tl_entity
  end

  def find_or_initialize_stop(gtfs_entity, operated_by: nil, parent_stop: nil)
    find_or_initialize(gtfs_entity) do |tl_entity|
      if gtfs_entity.parent_station.present?
        if gtfs_entity.location_type.to_i == 2
          tl_entity = StopEgress.new unless tl_entity.class == StopEgress # force new onestop_id
          tl_entity ||= StopEgress.new
        else
          tl_entity = StopPlatform.new unless tl_entity.class == StopPlatform # force new onestop_id
          tl_entity ||= StopPlatform.new
        end
        tl_entity.parent_stop = parent_stop
        tl_entity.platform_name = gtfs_entity.id
      else
        tl_entity ||= Stop.new
      end
      tl_entity.geometry = Stop::GEOFACTORY.point(*gtfs_entity.coordinates)
      tl_entity.name = gtfs_entity.stop_name.presence || gtfs_entity.id
      tl_entity.wheelchair_boarding = to_tfn(gtfs_entity.wheelchair_boarding)
      # Force station timezone, then try GTFS timezone, then try Operator timezone
      tl_entity.timezone = parent_stop.try(:timezone) || gtfs_entity.stop_timezone || operated_by.try(:timezone)
      tl_entity.tags = {
        stop_desc: gtfs_entity.stop_desc,
        stop_url: gtfs_entity.stop_url,
        zone_id: gtfs_entity.zone_id
      }
      tl_entity
    end
  end

  def find_or_initialize_station(gtfs_entity, operated_by: nil)
    find_or_initialize(gtfs_entity) do |tl_entity|
      tl_entity ||= find_or_initialize_stop(gtfs_entity, operated_by: operated_by)
      @station_children[gtfs_entity].each do |child_entity|
        find_or_initialize_stop(child_entity, operated_by: operated_by, parent_stop: tl_entity)
      end
      tl_entity
    end
  end

  def find_or_initialize_route(gtfs_entity, serves: [], operated_by: nil)
    find_or_initialize(gtfs_entity) { |tl_entity|
      tl_entity ||= Route.new
      tl_entity.geometry = nil # Calculate later from representative RSPs
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
      gtfs_trips = gtfs_entity.trips
      tl_entity.wheelchair_accessible = to_trips_accessible(gtfs_trips, :wheelchair_accessible)
      tl_entity.bikes_allowed = to_trips_accessible(gtfs_trips, :bikes_allowed)
      # Relations
      tl_entity.operated_by = operated_by
      tl_entity.serves = serves
      tl_entity
    }
  end

  def find_or_initialize_rsp(gtfs_entity, serves: [], traversed_by: nil)
    shape_line = @gtfs.shape_line(gtfs_entity.shape_id)
    shape_points = serves.map(&:coordinates)
    shape = shape_line || shape_points
    key = [traversed_by, shape, serves]
    find_or_initialize(gtfs_entity, key: key) { |tl_entity|
      tl_entity = RouteStopPattern.new # ignore EIFFs
      # Relations
      tl_entity.serves = serves
      tl_entity.stop_pattern = serves.map(&:onestop_id)
      tl_entity.traversed_by = traversed_by
      # Update distances
      # assume stop_times' and shapes' shape_dist_traveled are in the same units (a condition required by GTFS). TODO: validate that.
      shape_distances_traveled = shape_line.try(:shape_dist_traveled)
      stop_times = gtfs_entity.shape_dist_traveled.map { |i| GTFS::StopTime.new(shape_dist_traveled: i) }
      tl_entity.geometry = Geometry::LineString.line_string(Geometry::Lib.set_precision(shape, RouteStopPattern::COORDINATE_PRECISION))
      if shape_line.present? && shape_line.size > 1
        tl_entity.geometry_source = Geometry::GTFSShapeDistanceTraveled.validate_shape_dist_traveled(stop_times, shape_distances_traveled) ? :shapes_txt_with_dist_traveled : :shapes_txt
      else
        tl_entity.geometry_source = :trip_stop_points
      end
      calculate_rsp_distance(tl_entity, tl_entity.serves, shape_distances_traveled, stop_times)
      tl_entity
    }
  end

  def calculate_rsp_distance(rsp, stops, shape_distances_traveled, stop_times)
    begin
      if shape_distances_traveled && (rsp.geometry_source.to_sym.eql?(:shapes_txt_with_dist_traveled))
        # assume stop_times' and shapes' shape_dist_traveled are in the same units (a condition required by GTFS). TODO: validate that.
        Geometry::GTFSShapeDistanceTraveled::gtfs_shape_dist_traveled(rsp, stop_times, stops, shape_distances_traveled)
      elsif (rsp.geometry_source.to_sym.eql?(:trip_stop_points) && rsp.edited_attributes.empty?)
        # edited rsps will probably have a shape
        Geometry::DistanceCalculation.straight_line_distances(rsp, stops=stops)
      else
        Geometry::EnhancedOTPDistances.new.calculate_distances(rsp, stops=stops)
      end
    rescue => e
      log("Could not calculate distances for Route Stop Pattern: #{rsp.onestop_id}. Error: #{e}")
      Geometry::DistanceCalculation.fallback_distances(rsp, stops=stops)
    end
    return rsp.stop_distances
  end

  def to_tfn(value)
    case value.to_i
    when 0
      nil
    when 1
      true
    when 2
      false
    end
  end

  def to_trips_accessible(trips, key)
    # All combinations of 0,1,2 to:
    #    [:some_trips, :all_trips, :no_trips, :unknown]
    values = trips.map { |trip| trip.send(key).to_i }.to_set
    if values == Set.new([0])
      :unknown
    elsif values == Set.new([1])
      :all_trips
    elsif values == Set.new([2])
      :no_trips
    elsif values.include?(1)
      :some_trips
    else
      :no_trips
    end
  end
end
