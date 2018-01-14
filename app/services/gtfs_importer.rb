class GTFSImporter
  class Error < StandardError
  end

  def initialize(feed_version)
    @feed_version = feed_version
    @gtfs = @feed_version.open_gtfs
  end

  def clean_start
    GTFSAgency.where(feed_version: @feed_version).delete_all
    GTFSShape.where(feed_version: @feed_version).delete_all
    GTFSStop.where(feed_version: @feed_version).delete_all
    GTFSRoute.where(feed_version: @feed_version).delete_all
    GTFSTrip.where(feed_version: @feed_version).delete_all
    GTFSStopTime.where(feed_version: @feed_version).delete_all
  end

  def import
    default_agency_id = nil
    agency_ids = {}
    @gtfs.agencies.each do |agency|
      default_agency_id ||= agency.agency_id
      agency_ids[agency.agency_id] = GTFSAgency.create!(
        agency_id: agency.agency_id,
        agency_name: agency.agency_name,
        feed_version: @feed_version
      ).id
    end
    puts "agency_ids:"
    puts agency_ids

    stop_ids = {}
    @gtfs.stops.each do |stop|
      stop_ids[stop.stop_id] = GTFSStop.create!(
        stop_id: stop.stop_id,
        stop_name: stop.stop_name,
        stop_desc: stop.stop_desc,
        geometry: "POINT(#{stop.stop_lon.to_f} #{stop.stop_lat.to_f})",
        feed_version: @feed_version
      ).id
    end

    route_ids = {}
    @gtfs.routes.each do |route|
      route_ids[route.route_id] = GTFSRoute.create!(
        route_id: route.route_id,
        route_short_name: route.route_short_name,
        route_long_name: route.route_long_name,
        route_desc: route.route_desc,
        agency_id: agency_ids.fetch(route.agency_id || default_agency_id),
        feed_version: @feed_version
      )
    end

    @gtfs.load_shapes
    shape_lines = @gtfs.instance_variable_get('@shape_lines')
    shape_lines.each do |shape_id, shape_line|
      geom = shape_line.shapes.map { |s| [s.shape_pt_lon.to_f, s.shape_pt_lat.to_f, s_to_f(s.shape_dist_traveled)]}
      puts geom.inspect

    end

  end

  def s_to_f(value)
    value.nil? ? nil : value.to_f
  end
end
