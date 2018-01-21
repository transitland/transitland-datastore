class GTFSScheduleImporter
  class Error < StandardError
  end

  attr_accessor :feed, :feed_version, :gtfs

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
  end

  def load_schedule(trip_ids: nil)
    info("GTFSScheduleImport: #{@feed.onestop_id} #{@feed_version.sha1}")
    @gtfs = @feed_version.open_gtfs
    @gtfs.agencies
    @gtfs.routes
    @gtfs.stops
    @gtfs.trips

    # Lookup trips
    trip_ids = trip_ids || @gtfs.trips.map(&:trip_id)
    info("Trips: #{trip_ids.size}")

    # Lookup frequencies.txt
    gtfs_frequencies = {}
    if @gtfs.file_present?('frequencies.txt')
      gtfs_frequencies = @gtfs.frequencies.group_by(&:trip_id)
    end

    # Import
    ssps = []
    @gtfs.each_trip_stop_times(trip_ids, true) do |gtfs_trip_id, gtfs_stop_times|
      gtfs_trip = @gtfs.trip(gtfs_trip_id)
      # info("TRIP: #{gtfs_trip.id}")
      # Process frequencies
      (gtfs_frequencies[gtfs_trip.trip_id] || [nil]).each do |gtfs_frequency|
        ssp_trip = make_ssp_trip(gtfs_trip, gtfs_stop_times, gtfs_frequency: gtfs_frequency)
        ssps += ssp_trip
      end
      # Bulk insert
      if ssps.size >= 1000
        info("ScheduleStopPairs: #{ssps.size}")
        bulk_insert(ssps)
        ssps = []
      end
    end
    if ssps.size > 0
      info("ScheduleStopPairs: #{ssps.size}")
      bulk_insert(ssps)
      ssps = []
    end
  end

  # Compatibility
  def import_log
    @log.join("\n")
  end

  def ssp_perform_async(gtfs_trip_ids, *args)
    load_schedule(trip_ids: gtfs_trip_ids)
  end

  private

  def info(msg, indent: nil, plus: 0)
    @indent = indent if indent
    msg = ("\t"*@indent) + ("\t"*plus) + msg
    @log << msg
    log(msg)
  end

  def find_by_eiff(gtfs_entity)
    eiff = EntityImportedFromFeed.find_by(
      feed_version: @feed_version,
      entity_type: ENTITY_CLASS_MAP[gtfs_entity.class],
      gtfs_id: gtfs_entity.id
    )
    return unless eiff
    return unless eiff.entity
    return eiff.entity
  end

  def find_by_gtfs_entity(gtfs_entity)
    # TODO: check for existing key
    tl_entity = @entity_tl[gtfs_entity] || find_by_eiff(gtfs_entity)
    @entity_tl[gtfs_entity] = tl_entity
    tl_entity
  end

  def bulk_insert(ssps)
    ScheduleStopPair.import ssps, validate: false
  end

  def make_ssp_trip(gtfs_trip, gtfs_stop_times, gtfs_frequency: nil)
    # Lookup tl_route from gtfs_trip.route_id
    gtfs_route = @gtfs.route(gtfs_trip.route_id)
    unless gtfs_route
      info("Trip #{gtfs_trip.trip_id}: No GTFS Route for route_id: #{gtfs_trip.route_id}")
      return []
    end

    tl_route = find_by_gtfs_entity(gtfs_route)
    unless tl_route
      info("Trip #{gtfs_trip.trip_id}: Missing Route for route_id: #{gtfs_route.route_id}")
      return []
    end

    # Lookup tl_rsp from gtfs_trip.trip_id
    tl_rsp = find_by_gtfs_entity(gtfs_trip)
    unless tl_rsp
      info("Trip #{gtfs_trip.trip_id}: Missing RouteStopPattern for trip_id: #{gtfs_trip.trip_id}")
      return []
    end

    # Lookup gtfs_service_period from gtfs_trip.service_id
    gtfs_service_period = @gtfs.service_period(gtfs_trip.service_id)
    unless gtfs_service_period
      info("Trip #{gtfs_trip.trip_id}: Unknown GTFS ServicePeriod: #{gtfs_trip.service_id}")
      return []
    end

    # Lookup last stop for fallback Headsign
    last_stop_name = @gtfs.stop(gtfs_stop_times.last.stop_id).stop_name

    # Trip start & end times
    trip_start_time = GTFS::WideTime.parse(gtfs_stop_times.first.arrival_time || gtfs_stop_times.first.departure_time)
    trip_end_time = GTFS::WideTime.parse(gtfs_stop_times.last.departure_time || gtfs_stop_times.first.arrival_time)

    # Trip frequency
    frequency_start_time = GTFS::WideTime.parse(gtfs_frequency.try(:start_time))
    frequency_end_time = GTFS::WideTime.parse(gtfs_frequency.try(:end_time))
    frequency_type = to_frequency_type(gtfs_frequency)
    frequency_headway_seconds = gtfs_frequency.try(:headway_secs)

    # Create SSPs for all gtfs_stop_time edges
    ssp_trip = []
    gtfs_stop_times[0..-2].each_index do |i|
      # Get the tl_origin_stop and tl_destination_stop from gtfs_stop_time edge
      gtfs_origin_stop_time = gtfs_stop_times[i]
      gtfs_destination_stop_time = gtfs_stop_times[i+1]
      gtfs_origin_stop = @gtfs.stop(gtfs_origin_stop_time.stop_id)
      tl_origin_stop = find_by_gtfs_entity(gtfs_origin_stop)
      unless tl_origin_stop
        info("Trip #{gtfs_trip.trip_id}: Missing Stop for origin stop_id: #{gtfs_origin_stop.stop_id}")
        next
      end
      gtfs_destination_stop = @gtfs.stop(gtfs_destination_stop_time.stop_id)
      tl_destination_stop = find_by_gtfs_entity(gtfs_destination_stop)
      unless tl_destination_stop
        info("Trip #{gtfs_trip.trip_id}: Missing Stop for destination stop_id: #{gtfs_destination_stop.stop_id}")
        next
      end

      # Origin / departure times
      origin_arrival_time = GTFS::WideTime.parse(gtfs_origin_stop_time.arrival_time)
      origin_departure_time = GTFS::WideTime.parse(gtfs_origin_stop_time.departure_time)
      destination_arrival_time = GTFS::WideTime.parse(gtfs_destination_stop_time.arrival_time)
      destination_departure_time = GTFS::WideTime.parse(gtfs_destination_stop_time.departure_time)
      # Adjust frequency schedules to be relative to trip_start_time
      if frequency_start_time
        if origin_arrival_time
          origin_arrival_time = (origin_arrival_time - trip_start_time) + frequency_start_time
        end
        if origin_departure_time
          origin_departure_time = (origin_departure_time - trip_start_time) + frequency_start_time
        end
        if destination_arrival_time
          destination_arrival_time = (destination_arrival_time - trip_start_time) + frequency_start_time
        end
        if destination_departure_time
          destination_departure_time = (destination_departure_time - trip_start_time) + frequency_start_time
        end
      end

      # Create SSP
      ssp_trip << ScheduleStopPair.new(
        # Feed
        feed: @feed,
        feed_version: @feed_version,
        # Origin
        origin: tl_origin_stop,
        origin_timezone: tl_origin_stop.timezone,
        origin_arrival_time: origin_arrival_time,
        origin_departure_time: origin_departure_time,
        origin_dist_traveled: tl_rsp.stop_distances[i],
        # Destination
        destination: tl_destination_stop,
        destination_timezone: tl_destination_stop.timezone,
        destination_arrival_time: destination_arrival_time,
        destination_departure_time: destination_departure_time,
        destination_dist_traveled: tl_rsp.stop_distances[i+1],
        # Route
        route: tl_route,
        route_stop_pattern: tl_rsp,
        # Operator
        operator: tl_route.operator,
        # Trip
        trip: gtfs_trip.trip_id,
        trip_headsign: (gtfs_origin_stop_time.stop_headsign || gtfs_trip.trip_headsign || last_stop_name).presence,
        trip_short_name: gtfs_trip.trip_short_name.presence,
        shape_dist_traveled: gtfs_destination_stop_time.shape_dist_traveled.to_f,
        block_id: gtfs_trip.block_id,
        # Accessibility
        pickup_type: to_pickup_type(gtfs_origin_stop_time.pickup_type),
        drop_off_type: to_pickup_type(gtfs_destination_stop_time.drop_off_type),
        wheelchair_accessible: to_tfn(gtfs_trip.wheelchair_accessible),
        bikes_allowed: to_tfn(gtfs_trip.bikes_allowed),
        # service period
        service_start_date: gtfs_service_period.start_date,
        service_end_date: gtfs_service_period.end_date,
        service_days_of_week: gtfs_service_period.iso_service_weekdays,
        service_added_dates: gtfs_service_period.added_dates,
        service_except_dates: gtfs_service_period.except_dates,
        # frequency
        frequency_type: frequency_type,
        frequency_start_time: frequency_start_time,
        frequency_end_time: frequency_end_time,
        frequency_headway_seconds: frequency_headway_seconds
      )
    end

    # Interpolate stop_times
    begin
      ScheduleStopPair.interpolate(ssp_trip)
    rescue StandardError => e
      info("Trip #{gtfs_trip.trip_id}: Could not process arrival/departure times, skipping: #{e.message}")
      return []
    end

    # Skip trip if validation errors
    unless ssp_trip.map(&:valid?).all?
      info("Trip #{gtfs_trip.trip_id}: Invalid SSPs, skipping")
      return []
    end

    # Return ssps
    return ssp_trip
  end

  def to_frequency_type(gtfs_frequency)
    value = gtfs_frequency.try(:exact_times).to_i
    if gtfs_frequency.nil?
      nil
    elsif value == 0
      :not_exact
    elsif value == 1
      :exact
    end
  end

  def to_pickup_type(value)
    case value.to_i
    when 0
      nil
    when 1
      :unavailable
    when 2
      :ask_agency
    when 3
      :ask_driver
    end
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
end
