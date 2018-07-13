
class GTFSImporter
  class Error < StandardError
  end

  def initialize(feed_version)
    @feed_version = feed_version
    @gtfs = @feed_version.open_gtfs
    # mappings
    @agency_ids = {}
    @stop_ids = {}
    @trip_ids = {}
    @route_ids = {}
    @shape_ids = {}
  end

  def clean_start
    GTFSAgency.where(feed_version: @feed_version).delete_all
    GTFSCalendarDate.where(feed_version: @feed_version).delete_all
    GTFSCalendar.where(feed_version: @feed_version).delete_all
    GTFSFareAttribute.where(feed_version: @feed_version).delete_all
    GTFSFareRule.where(feed_version: @feed_version).delete_all
    GTFSFeedInfo.where(feed_version: @feed_version).delete_all
    GTFSFrequency.where(feed_version: @feed_version).delete_all
    GTFSRoute.where(feed_version: @feed_version).delete_all
    GTFSShape.where(feed_version: @feed_version).delete_all
    GTFSStop.where(feed_version: @feed_version).delete_all
    GTFSStopTime.where(feed_version: @feed_version).delete_all
    GTFSTransfer.where(feed_version: @feed_version).delete_all
    GTFSTrip.where(feed_version: @feed_version).delete_all
  end

  def time(msg, &block)
    t = Time.now
    block.call
    log("#{msg}: #{((Time.now-t)).round(2)}")
  end

  def import
    # Import order is important.
    t_import = Time.now
    time('agencies') { import_agencies }
    time('stops') { import_stops }
    time('routes') { import_routes }
    time('shapes') { import_shapes }
    time('trips') { import_trips }
    # time('calendar') import_calendar
    # time('calendar_dates') import_calendar_dates
    # time('optional') import_optional
    time('stop_times') { import_stop_times }
    log("total: #{((Time.now-t_import).round(2))}")
  end

  def import_agencies
    @gtfs.each_agency do |agency|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:agency_id] = agency.agency_id
      params[:agency_name] = agency.agency_name
      params[:agency_url] = agency.agency_url
      params[:agency_timezone] = agency.agency_timezone
      params[:agency_lang] = agency.agency_lang
      params[:agency_phone] = agency.agency_phone
      params[:agency_fare_url] = agency.agency_fare_url
      params[:agency_email] = agency.agency_email
      @agency_ids[agency.agency_id] = GTFSAgency.create!(params).id
    end
  end

  def import_stops
    parent_ids = {}
    f = GTFSStop.geofactory
    @gtfs.each_stop do |stop|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:stop_id] = stop.stop_id
      params[:stop_code] = stop.stop_code
      params[:stop_name] = stop.stop_name
      params[:stop_desc] = stop.stop_desc
      params[:stop_url] = stop.stop_url
      params[:zone_id] = stop.zone_id
      params[:location_type] = gtfs_int(stop.location_type)
      params[:stop_timezone] = stop.stop_timezone
      params[:wheelchair_boarding] = gtfs_int(stop.wheelchair_boarding)
      params[:geometry] = f.point(
        gtfs_float(stop.stop_lon),
        gtfs_float(stop.stop_lat)
      )
      @stop_ids[stop.stop_id] = GTFSStop.create!(params).id
      parent_ids[stop.stop_id] = stop.parent_station if stop.parent_station.presence
    end
    # Link parent_stations
    parent_ids.each do |stop_id,parent_station|
      GTFSStop.where(id: @stop_ids.fetch(stop_id)).update_all(parent_station_id: @stop_ids.fetch(parent_station))
    end
  end

  def import_routes
    @gtfs.each_route do |route|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:route_id] = route.route_id
      params[:route_short_name] = route.route_short_name || "" # spec
      params[:route_long_name] = route.route_long_name || "" # spec
      params[:route_desc] = route.route_desc
      params[:route_type] = gtfs_int(route.route_type)
      params[:route_url] = route.route_url
      params[:route_color] = route.route_color
      params[:route_text_color] = route.route_text_color
      params[:agency_id] = @agency_ids.fetch(route.agency_id || @agency_ids.keys.first)
      @route_ids[route.route_id] = GTFSRoute.create!(params).id
    end
  end

  def import_shapes
    f = GTFSShape.geofactory
    @gtfs.shape_id_chunks(100_000) do |shape_id_chunk|
      log("processing shape_id_chunks: #{shape_id_chunk}")
      @gtfs.each_shape_line(shape_id_chunk) do |shape_line|
        log("shape_line: #{shape_line.shape_id} shapes #{shape_line.shapes.size}")
        params = {}
        params[:feed_version_id] = @feed_version.id
        params[:shape_id] = shape_line.shape_id
        params[:geometry] = f.line_string(
          shape_line.shapes.map { |s|
            f.point(
              gtfs_float(s.shape_pt_lon),
              gtfs_float(s.shape_pt_lat),
              gtfs_float(s.shape_dist_traveled)
            )
          }
        )
        @shape_ids[shape_line.shape_id] = GTFSShape.create!(params).id
      end
    end
  end

  def import_trips
    @gtfs.each_trip do |trip|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:trip_id] = trip.trip_id
      params[:service_id] = trip.service_id
      params[:trip_headsign] = trip.trip_headsign
      params[:trip_short_name] = trip.trip_short_name
      params[:direction_id] = gtfs_int(trip.direction_id)
      params[:block_id] = trip.block_id
      params[:wheelchair_accessible] = gtfs_int(trip.wheelchair_accessible)
      params[:bikes_allowed] = gtfs_int(trip.bikes_allowed)
      params[:route_id] = @route_ids.fetch(trip.route_id)
      params[:shape_id] = @shape_ids[trip.shape_id] # optional
      @trip_ids[trip.trip_id] = GTFSTrip.create!(params).id
    end
  end

  def import_calendar_dates
    if @gtfs.file_present?('calendar_dates.txt')
    end
  end

  def import_calendar
    if @gtfs.file_present?('calendar.txt')
    end
  end

  def import_optional
    # Optional files
    # fare_attributes.txt
    # fare_rules.txt
    # feed_info.txt
    # frequency.txt
    if @gtfs.file_present?('frequency.txt')
    end
    # transfers.txt
    if @gtfs.file_present?('transfers.txt')
    end
  end

  def import_stop_times
    total_stop_times = 0
    @gtfs.trip_id_chunks(100_000) do |trip_id_chunk|
      log("processing trip_id_chunks: #{trip_id_chunk}")
      chunk_stop_times = []
      @gtfs.each_trip_stop_times(trip_id_chunk) do |trip_id, stop_times|
        log("stop_times: trip #{trip_id} stop_times #{stop_times.size}")
        trip_stop_times = []
        stop_times.each_index do |i|
          origin = stop_times[i]
          destination = stop_times[i+1] # last stop is nil
          params = {}
          params[:feed_version_id] = @feed_version.id
          params[:stop_sequence] = gtfs_int(origin.stop_sequence)
          params[:stop_headsign] = origin.stop_headsign
          params[:pickup_type] = gtfs_int(origin.pickup_type)
          params[:drop_off_type] = gtfs_int(origin.drop_off_type)
          params[:shape_dist_traveled] = gtfs_float(origin.shape_dist_traveled)
          params[:trip_id] = @trip_ids.fetch(origin.trip_id)
          # params[:timepoint] = gtfs_int(origin.timepoint)
          # where
          params[:stop_id] = @stop_ids.fetch(origin.stop_id)
          params[:arrival_time] = gtfs_time(origin.arrival_time)
          params[:departure_time] = gtfs_time(origin.departure_time)
          # for convenience
          params[:destination_id] = @stop_ids.fetch(destination.stop_id) if destination
          params[:destination_arrival_time] = gtfs_time(destination.arrival_time) if destination
          trip_stop_times << GTFSStopTime.new(params)
        end
        # Validate
        interpolate_stop_times(trip_stop_times)
        # next unless trip_stop_times.map(&:valid?).all?
        chunk_stop_times += trip_stop_times
        if chunk_stop_times.size > 1_000
          GTFSStopTime.import(chunk_stop_times)
          total_stop_times += chunk_stop_times.size
          log("... import #{chunk_stop_times.size}")
          chunk_stop_times = []
        end
      end
      GTFSStopTime.import(chunk_stop_times)
      total_stop_times += chunk_stop_times.size
      log("... import #{chunk_stop_times.size}")
    end
    log("total stop_times: #{total_stop_times}")
  end

  private

  def gtfs_int(value)
    Integer(value) unless value.nil? || value.empty?
  end

  def gtfs_float(value)
    Float(value) unless value.nil? || value.empty?
  end

  def gtfs_time(value)
    # handles nil and empty
    GTFS::WideTime.parse(value).to_seconds
  end

  def gtfs_date(value)
    Date.parse(value) unless value.nil? || value.empty?
  end

  def gtfs_boolean(value)
    to_int(value) == 1 ? true : false
  end

  SHAPE_STOP_DISTANCE={}
  def interpolate_stop_times(stop_times)
    return
    shape_id = GTFSTrip.find(stop_times.first.trip_id).shape_id
    origins = []
    stop_times.each do |st|
      origins << st.stop_id if SHAPE_STOP_DISTANCE[[st.stop_id, shape_id]].nil?
    end
    s = 'gtfs_stops.id, ST_LineLocatePoint(gtfs_shapes.geometry::geometry, ST_ClosestPoint(gtfs_shapes.geometry::geometry, ST_SetSRID(gtfs_stops.geometry, 4326))) AS line_s'
    GTFSStop.where(id: origins).select(s).joins('INNER JOIN gtfs_shapes ON gtfs_shapes.id='+shape_id.to_s).each do |row|
      SHAPE_STOP_DISTANCE[[row.id, shape_id]] = row.line_s
    end


    s = stop_times.size
    i = 0
    until i == s do
      st1 = stop_times[i]
      i += 1
      j = i
      ip = [st1]
      until j == s do
        st2 = stop_times[j]
        j += 1
        break if st2.arrival_time
        ip << st2        
      end
    end
  end
end
