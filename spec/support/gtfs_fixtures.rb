def create_gtfs_fixture(filename, feed_version)
    # load('spec/support/gtfs_fixtures.rb')
    export = {
        agencies: GTFSAgency.where(feed_version: feed_version).map { |e| e.slice(:id, :agency_id, :agency_name, :agency_url, :agency_timezone, :agency_lang, :agency_phone, :agency_fare_url, :agency_email) },
        stops: GTFSStop.where(feed_version: feed_version).map { |e| e.slice(:id, :stop_id, :stop_code, :stop_name, :stop_desc, :zone_id, :stop_url, :location_type, :stop_timezone, :wheelchair_boarding, :geometry) },
        routes: GTFSRoute.where(feed_version: feed_version).map { |e| e.slice(:id, :agency_id, :route_id, :route_short_name, :route_long_name, :route_desc, :route_type, :route_url, :route_color, :route_text_color) },
        shapes: GTFSShape.where(feed_version: feed_version).map { |e| e.slice(:id, :shape_id, :geometry ) },
        trips: GTFSTrip.where(feed_version: feed_version).map { |e| e.slice(:id, :route_id, :service_id, :trip_id, :trip_headsign, :trip_short_name, :direction_id, :block_id, :wheelchair_accessible, :bikes_allowed) },
        stop_times: GTFSStopTime.where(feed_version: feed_version).map { |e| e.slice(:stop_sequence, :stop_headsign, :pickup_type, :drop_off_type, :shape_dist_traveled, :timepoint, :trip_id, :origin_id, :destination_id, :origin_arrival_time, :origin_departure_time, :destination_arrival_time) }
    }
    File.open(filename, 'w') do |f|
        f.write(export.to_json)
    end
end

def load_gtfs_fixture(filename)
    agency_map = {}
    stop_map = {}
    route_map = {}
    shape_map = {}
    trip_map = {}
    fv = create(:feed_version)
    data = JSON.parse(File.read(filename))

    data['agencies'].each do |e|
        eid = e.delete('id')
        e['feed_version_id'] = fv.id
        s = GTFSAgency.create!(**e.symbolize_keys)
        agency_map[eid] = s.id
    end
    data['stops'].each do |e|
        eid = e.delete('id')
        e['feed_version_id'] = fv.id
        s = GTFSStop.create!(**e.symbolize_keys)
        stop_map[eid] = s.id
    end
    data['routes'].each do |e|
        eid = e.delete('id')
        e['agency_id'] = agency_map.fetch(e['agency_id'])
        e['feed_version_id'] = fv.id
        s = GTFSRoute.create!(**e.symbolize_keys)
        route_map[eid] = s.id
    end
    data['shapes'].each do |e|
        eid = e.delete('id')
        e['feed_version_id'] = fv.id
        s = GTFSShape.create!(**e.symbolize_keys)
        shape_map[eid] = s.id
    end
    data['trips'].each do |e|
        eid = e.delete('id')
        e['feed_version_id'] = fv.id
        e['route_id'] = route_map.fetch(e['route_id'])
        e['shape_id'] = shape_map.fetch(e['shape_id'], nil) # optional
        s = GTFSTrip.create!(**e.symbolize_keys)
        trip_map[eid] = s.id
    end
    data['stop_times'].each do |e|
        eid = e.delete('id')
        e['feed_version_id'] = fv.id
        e['trip_id'] = trip_map.fetch(e['trip_id'])
        e['origin_id'] = stop_map.fetch(e['origin_id'])
        # e['destination_id'] = stop_map.fetch(e['destination_id'])
        GTFSStopTime.new(**e.symbolize_keys).save!(validate: false)
    end

    return fv
end