class GTFSGraph2
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
      debug "GTFS_AGENCY: #{gtfs_agency.agency_id}"
      tl_operator = oifs[gtfs_agency.agency_id]
      next unless tl_operator
      @entity_tl[gtfs_agency] = tl_operator
      add_eiff(tl_operator, gtfs_agency)

      # Routes
      gtfs_agency.routes.each do |gtfs_route|
        debug "\tGTFS_ROUTE: #{gtfs_route.route_id}"

        # Trips: Pass 1: Create Stops
        tl_route_serves = []
        tl_trip_stop_sequence = {}
        gtfs_route.trips.each do |gtfs_trip|
          debug "\t\tGTFS_TRIP: #{gtfs_trip.trip_id}"
          tl_trip_stop_sequence[gtfs_trip] = []
          gtfs_trip.stop_sequence.each do |gtfs_stop|
            debug "\t\t\tGTFS_STOP: #{gtfs_stop.stop_id}"
            tl_stop = find_or_initialize_stop(gtfs_stop, operated_by: tl_operator)
            tl_route_serves << tl_stop
            tl_trip_stop_sequence[gtfs_trip] << tl_stop
          end
        end

        # Create Route
        tl_route = find_or_initialize_route(gtfs_route, serves: tl_route_serves.to_set, operated_by: tl_operator)

        # Trips: Pass 2: Create RSPs
        tl_route_rsps = Set.new
        gtfs_route.trips.each do |gtfs_trip|
          next unless gtfs_trip.stop_sequence.size > 1
          tl_rsp = find_or_initialize_rsp(gtfs_trip, serves: tl_trip_stop_sequence[gtfs_trip], traversed_by: tl_route)
          calculate_rsp_distance(tl_rsp) # TODO
          tl_route_rsps << tl_rsp
        end

        # Update Route geometry
        representative_rsps = Route.representative_geometry(tl_route, tl_route_rsps)
        Route.geometry_from_rsps(tl_route, representative_rsps)
      end
    end
  end

  def create_changeset
    # Convert associations
    entities = @entity_tl.values.to_set
    entities.each do |tl_entity|
      if tl_entity.instance_of?(StopPlatform)
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
      graph_log "Changeset Error: #{e}"
      graph_log "Payload:"
      graph_log e.payload.to_json
      raise e
    rescue StandardError => e
      graph_log "Error: #{e}"
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

  private

  def graph_log(msg)
    @log << msg
    log(msg)
    puts msg
  end

  def debug(msg)
    puts msg
  end

  def private_create_change_osr
    ##### Backwards compat #####
    load_graph
    entities = @entity_tl.values.to_set

    # Create FeedVersion issue and fail if no matching operators found.
    Issue.where(issue_type: 'feed_import_no_operators_found').issues_of_entity(feed_version).each(&:deprecate)
    # ... create new issue
    if @entity_tl.size == 0
      known_agency_ids = @feed.operators_in_feed.map(&:gtfs_agency_id).map{ |s| "\"#{s}\"" }.join(', ')
      feed_agency_ids = @gtfs.agencies.map(&:agency_id).map{ |s| "\"#{s}\"" }.join(', ')
      details = "No agencies found.\noperators_in_feed agency_ids: #{known_agency_ids}\nfeed agency_ids: #{feed_agency_ids}"
      issue = Issue.new(issue_type: 'feed_import_no_operators_found', details: details)
      issue.entities_with_issues.new(entity: @feed_version)
      issue.save!
      fail GTFSGraph::Error.new('No agencies found that match operators_in_feed')
    end

    # Update Feed Geometry
    @feed.set_bounding_box_from_stops(entities.select { |i| i.is_a?(Stop) })
    @feed.save!

    # Create changeset
    changeset = create_changeset

    # Delete old RSPs
    feed_rsps = Set.new(@feed.imported_route_stop_patterns.where("edited_attributes='{}'").pluck(:onestop_id))
    rsps_to_remove = feed_rsps - Set.new(entities.select { |i| i.is_a?(RouteStopPattern)}.map(&:onestop_id))
    if rsps_to_remove.size > 0
      changeset.change_payloads.create!(payload: {
        changes: rsps_to_remove.map {|i| {action: "destroy", routeStopPattern: {onestopId: i}}}
      })
    end

    # Apply changeset
    changeset.apply!
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
      # log "FOUND GTFS: #{gtfs_entity.class.name} #{gtfs_entity.id} -> #{tl_entity.onestop_id}"
      add_eiff(tl_entity, gtfs_entity)
      return tl_entity
    end

    tl_entity = find_by_eiff(gtfs_entity)
    if tl_entity
      log "#{gtfs_entity.class.name} eiff: #{gtfs_entity.id} -> #{tl_entity.onestop_id}"
    else
      log "#{gtfs_entity.class.name} new: #{gtfs_entity.id} -> ..."
    end

    # Create / Update
    tl_entity = yield(tl_entity)

    # Cache
    tl_entity.onestop_id ||= tl_entity.generate_onestop_id
    tl_entity = @onestop_tl[tl_entity.onestop_id] || tl_entity
    @onestop_tl[tl_entity.onestop_id] = tl_entity
    @entity_tl[key] = tl_entity
    add_eiff(tl_entity, gtfs_entity)
    tl_entity
  end

  def find_or_initialize_stop(gtfs_entity, operated_by: nil)
    find_or_initialize(gtfs_entity) { |tl_entity|
      if gtfs_entity.parent_station.present?
        tl_entity ||= StopPlatform.new
        tl_entity.parent_stop = find_or_initialize_stop(@gtfs.stop(gtfs_entity.parent_station), operated_by: operated_by)
      else
        tl_entity ||= Stop.new
      end
      tl_entity.geometry = Stop::GEOFACTORY.point(*gtfs_entity.coordinates)
      tl_entity.name = gtfs_entity.stop_name
      tl_entity.wheelchair_boarding = nil
      tl_entity.timezone = gtfs_entity.stop_timezone || operated_by.try(:timezone)
      tl_entity.tags = {
        stop_desc: gtfs_entity.stop_desc,
        stop_url: gtfs_entity.stop_url,
        zone_id: gtfs_entity.zone_id
      }
      tl_entity
    }
  end

  def find_or_initialize_route(gtfs_entity, serves: [], operated_by: nil)
    find_or_initialize(gtfs_entity) { |tl_entity|
      tl_entity ||= Route.new
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
      gtfs_trips = gtfs_entity.trips
      tl_entity.wheelchair_accessible = :unknown # TODO
      tl_entity.bikes_allowed = :unknown # TODO
      # Relations
      tl_entity.operated_by = operated_by
      tl_entity.serves = serves
      tl_entity
    }
  end

  def find_or_initialize_rsp(gtfs_entity, serves: [], traversed_by: nil)
    shape_line = @gtfs.shape_line(gtfs_entity.shape_id)
    shape_points = serves.map(&:coordinates)
    geometry = RouteStopPattern.line_string(RouteStopPattern.set_precision(shape_line || shape_points))
    key = [geometry, serves]
    find_or_initialize(gtfs_entity, key: key) { |tl_entity|
      tl_entity ||= RouteStopPattern.new
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
      tl_entity
    }
  end

  def calculate_rsp_distance(rsp)
    # TODO: MOVE
    stops = rsp.serves
    begin
      # edited rsps will probably have a shape
      if (rsp.geometry_source.eql?("shapes_txt_with_dist_traveled"))
        # do nothing
      elsif (rsp.geometry_source.eql?("trip_stop_points") && rsp.edited_attributes.empty?)
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
