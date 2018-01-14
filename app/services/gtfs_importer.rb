
class GTFSImporter
  class Error < StandardError
  end

  def initialize(feed_version)
    @feed_version = feed_version
    @gtfs = @feed_version.open_gtfs
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

  def import
    default_agency_id = nil
    agency_ids = {}
    @gtfs.agencies.each do |agency|
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
      agency_ids[agency.agency_id] = GTFSAgency.create!(params).id
      default_agency_id ||= agency.agency_id
    end

    stop_ids = {}
    f = GTFSStop.geofactory
    @gtfs.stops.each do |stop|
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
      # params[:parent_station_id] = ...
      params[:geometry] = f.point(
        gtfs_float(stop.stop_lon),
        gtfs_float(stop.stop_lat)
      )
      stop_ids[stop.stop_id] = GTFSStop.create!(params).id
    end
    # Second pass to link parent_stations
    @gtfs.stops.each do |stop|
      next unless stop.parent_station.presence
      GTFSStop.find(stop_ids.fetch(stop.stop_id)).update!(parent_station_id: stop_ids.fetch(stop.parent_station))
    end

    route_ids = {}
    @gtfs.routes.each do |route|
      params = {}
      params[:feed_version_id] = @feed_version.id
      params[:route_id] = route.route_id
      params[:route_short_name] = route.route_short_name
      params[:route_long_name] = route.route_long_name
      params[:route_desc] = route.route_desc
      params[:route_type] = gtfs_int(route.route_type)
      params[:route_url] = route.route_url
      params[:route_color] = route.route_color
      params[:route_text_color] = route.route_text_color
      params[:agency_id] = agency_ids.fetch(route.agency_id || default_agency_id)
      route_ids[route.route_id] = GTFSRoute.create!(params).id
    end

    @gtfs.load_shapes
    f = GTFSShape.geofactory
    shape_ids = {}
    shape_lines = @gtfs.instance_variable_get('@shape_lines')
    shape_lines.each do |shape_id, shape_line|
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
      shape_ids[shape_line.shape_id] = GTFSShape.create!(params).id
    end

    trip_ids = {}
    @gtfs.trips.each do |trip|
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
      params[:route_id] = route_ids.fetch(trip.route_id)
      params[:shape_id] = shape_ids[trip.shape_id] # optional
      trip_ids[trip.trip_id] = GTFSTrip.create!(params).id
    end

    # Optional

  end

  def s_to_f(value)
    value.nil? ? nil : value.to_f
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
end
