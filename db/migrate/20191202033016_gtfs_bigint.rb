class GTFSBigint < ActiveRecord::Migration
  def change
    remove_foreign_key "active_agencies", "feed_versions"
    remove_foreign_key "active_agencies", column: "id"
    remove_foreign_key "active_routes", "feed_versions"
    remove_foreign_key "active_routes", column: "agency_id"
    remove_foreign_key "active_routes", column: "id"
    remove_foreign_key "active_stops", "feed_versions"
    remove_foreign_key "active_stops", column: "id"
    remove_foreign_key "active_stops", column: "parent_station"
    remove_foreign_key "agency_geometries", "feed_versions"
    remove_foreign_key "agency_geometries", column: "agency_id"
    remove_foreign_key "feed_states", column: "feed_id"
    remove_foreign_key "feed_states", "feed_versions"
    remove_foreign_key "feed_version_geometries", "feed_versions"
    remove_foreign_key "feed_version_gtfs_imports", "feed_versions"
    remove_foreign_key "feed_versions", column: "feed_id"
    remove_foreign_key "gtfs_agencies", "feed_versions"
    remove_foreign_key "gtfs_calendar_dates", "feed_versions"
    remove_foreign_key "gtfs_calendar_dates", column: "service_id"
    remove_foreign_key "gtfs_calendars", "feed_versions"
    remove_foreign_key "gtfs_fare_attributes", "feed_versions"
    remove_foreign_key "gtfs_fare_rules", "feed_versions"
    remove_foreign_key "gtfs_fare_rules", column: "fare_id"
    remove_foreign_key "gtfs_feed_infos", "feed_versions"
    remove_foreign_key "gtfs_frequencies", "feed_versions"
    remove_foreign_key "gtfs_frequencies", column: "trip_id"
    remove_foreign_key "gtfs_routes", "feed_versions"
    remove_foreign_key "gtfs_routes", column: "agency_id"
    remove_foreign_key "gtfs_stop_times", "feed_versions"
    remove_foreign_key "gtfs_stop_times", column: "stop_id"
    remove_foreign_key "gtfs_stop_times", column: "trip_id"
    remove_foreign_key "gtfs_stops", "feed_versions"
    remove_foreign_key "gtfs_transfers", "feed_versions"
    remove_foreign_key "gtfs_transfers", column: "from_stop_id"
    remove_foreign_key "gtfs_transfers", column: "to_stop_id"
    remove_foreign_key "gtfs_trips", "feed_versions"
    remove_foreign_key "gtfs_trips", column: "service_id"
    remove_foreign_key "gtfs_trips", column: "route_id"
    remove_foreign_key "route_geometries", "feed_versions"
    remove_foreign_key "route_geometries", column: "route_id"
    remove_foreign_key "route_geometries", column: "shape_id"
    remove_foreign_key "route_stops", "feed_versions"
    remove_foreign_key "route_stops", column: "agency_id"
    remove_foreign_key "route_stops", column: "route_id"
    remove_foreign_key "route_stops", column: "stop_id"

    # change everything to bigint

    change_column :current_feeds, :id, :bigint
    change_column :feed_versions, :id, :bigint
    change_column :feed_versions, :feed_id, :bigint
    change_column :feed_states, :id, :bigint
    change_column :feed_states, :feed_version_id, :bigint
    change_column :feed_states, :feed_id, :bigint
    change_column :feed_version_gtfs_imports, :id, :bigint
    change_column :feed_version_gtfs_imports, :feed_version_id, :bigint

    change_column :gtfs_agencies        , :id, :bigint
    change_column :gtfs_calendar_dates  , :id, :bigint
    change_column :gtfs_calendars       , :id, :bigint
    change_column :gtfs_fare_attributes , :id, :bigint
    change_column :gtfs_fare_rules      , :id, :bigint
    change_column :gtfs_feed_infos      , :id, :bigint
    change_column :gtfs_frequencies     , :id, :bigint
    change_column :gtfs_routes          , :id, :bigint
    change_column :gtfs_shapes          , :id, :bigint
    change_column :gtfs_stop_times      , :id, :bigint
    change_column :gtfs_stops           , :id, :bigint
    change_column :gtfs_transfers       , :id, :bigint
    change_column :gtfs_trips           , :id, :bigint

    change_column :gtfs_agencies        , :feed_version_id, :bigint
    change_column :gtfs_calendar_dates  , :feed_version_id, :bigint
    change_column :gtfs_calendars       , :feed_version_id, :bigint
    change_column :gtfs_fare_attributes , :feed_version_id, :bigint
    change_column :gtfs_fare_rules      , :feed_version_id, :bigint
    change_column :gtfs_feed_infos      , :feed_version_id, :bigint
    change_column :gtfs_frequencies     , :feed_version_id, :bigint
    change_column :gtfs_routes          , :feed_version_id, :bigint
    change_column :gtfs_shapes          , :feed_version_id, :bigint
    change_column :gtfs_stop_times      , :feed_version_id, :bigint
    change_column :gtfs_stops           , :feed_version_id, :bigint
    change_column :gtfs_transfers       , :feed_version_id, :bigint
    change_column :gtfs_trips           , :feed_version_id, :bigint

    change_column :gtfs_trips, :route_id, :bigint
    change_column :gtfs_trips, :service_id, :bigint
    change_column :gtfs_calendar_dates, :service_id, :bigint
    change_column :gtfs_routes, :agency_id, :bigint
    change_column :gtfs_stop_times, :stop_id, :bigint
    change_column :gtfs_stop_times, :trip_id, :bigint
    change_column :gtfs_fare_rules, :fare_id, :bigint
    change_column :gtfs_transfers, :from_stop_id, :bigint
    change_column :gtfs_transfers, :to_stop_id, :bigint
    change_column :gtfs_frequencies, :trip_id, :bigint

    change_column :gtfs_stops, :parent_station, :bigint
    add_foreign_key "gtfs_stops", "gtfs_stops", column: "parent_station"
    
    change_column :gtfs_fare_attributes, :agency_id, :bigint
    add_foreign_key "gtfs_fare_attributes", "gtfs_agencies", column: "agency_id"

    change_column :gtfs_fare_rules, :route_id, :bigint
    add_foreign_key "gtfs_fare_rules", "gtfs_routes", column: "route_id"

    change_column :gtfs_trips, :shape_id, :bigint
    add_foreign_key "gtfs_trips", "gtfs_shapes", column: "shape_id"

    # adjust sequences
    execute "alter sequence feed_version_gtfs_imports_id_seq as bigint"
    execute "alter sequence feed_states_id_seq as bigint"
    execute "alter sequence feed_versions_id_seq as bigint"
    execute "alter sequence current_feeds_id_seq as bigint"

    execute "alter sequence gtfs_agencies_id_seq as bigint"
    execute "alter sequence gtfs_calendar_dates_id_seq as bigint"
    execute "alter sequence gtfs_calendars_id_seq as bigint"
    execute "alter sequence gtfs_fare_attributes_id_seq as bigint"
    execute "alter sequence gtfs_fare_rules_id_seq as bigint"
    execute "alter sequence gtfs_feed_infos_id_seq as bigint"
    execute "alter sequence gtfs_frequencies_id_seq as bigint"
    execute "alter sequence gtfs_routes_id_seq as bigint"
    execute "alter sequence gtfs_shapes_id_seq as bigint"
    execute "alter sequence gtfs_stop_times_id_seq as bigint"
    execute "alter sequence gtfs_stops_id_seq as bigint"
    execute "alter sequence gtfs_transfers_id_seq as bigint"
    execute "alter sequence gtfs_trips_id_seq as bigint"

    # add foreign keys back
    add_foreign_key "active_agencies", "feed_versions"
    add_foreign_key "active_agencies", "gtfs_agencies", column: "id"
    add_foreign_key "active_routes", "feed_versions"
    add_foreign_key "active_routes", "gtfs_agencies", column: "agency_id"
    add_foreign_key "active_routes", "gtfs_routes", column: "id"
    add_foreign_key "active_stops", "feed_versions"
    add_foreign_key "active_stops", "gtfs_stops", column: "id"
    add_foreign_key "active_stops", "gtfs_stops", column: "parent_station"
    add_foreign_key "agency_geometries", "feed_versions"
    add_foreign_key "agency_geometries", "gtfs_agencies", column: "agency_id"
    add_foreign_key "feed_states", "current_feeds", column: "feed_id"
    add_foreign_key "feed_states", "feed_versions"
    add_foreign_key "feed_version_geometries", "feed_versions"
    add_foreign_key "feed_version_gtfs_imports", "feed_versions"
    add_foreign_key "feed_versions", "current_feeds", column: "feed_id"
    add_foreign_key "gtfs_agencies", "feed_versions"
    add_foreign_key "gtfs_calendar_dates", "feed_versions"
    add_foreign_key "gtfs_calendar_dates", "gtfs_calendars", column: "service_id"
    add_foreign_key "gtfs_calendars", "feed_versions"
    add_foreign_key "gtfs_fare_attributes", "feed_versions"
    add_foreign_key "gtfs_fare_rules", "feed_versions"
    add_foreign_key "gtfs_fare_rules", "gtfs_fare_attributes", column: "fare_id"
    add_foreign_key "gtfs_feed_infos", "feed_versions"
    add_foreign_key "gtfs_frequencies", "feed_versions"
    add_foreign_key "gtfs_frequencies", "gtfs_trips", column: "trip_id"
    add_foreign_key "gtfs_routes", "feed_versions"
    add_foreign_key "gtfs_routes", "gtfs_agencies", column: "agency_id"
    add_foreign_key "gtfs_stop_times", "feed_versions"
    add_foreign_key "gtfs_stop_times", "gtfs_stops", column: "stop_id"
    add_foreign_key "gtfs_stop_times", "gtfs_trips", column: "trip_id"
    add_foreign_key "gtfs_stops", "feed_versions"
    add_foreign_key "gtfs_transfers", "feed_versions"
    add_foreign_key "gtfs_transfers", "gtfs_stops", column: "from_stop_id"
    add_foreign_key "gtfs_transfers", "gtfs_stops", column: "to_stop_id"
    add_foreign_key "gtfs_trips", "feed_versions"
    add_foreign_key "gtfs_trips", "gtfs_calendars", column: "service_id"
    add_foreign_key "gtfs_trips", "gtfs_routes", column: "route_id"
    add_foreign_key "route_geometries", "feed_versions"
    add_foreign_key "route_geometries", "gtfs_routes", column: "route_id"
    add_foreign_key "route_geometries", "gtfs_shapes", column: "shape_id"
    add_foreign_key "route_stops", "feed_versions"
    add_foreign_key "route_stops", "gtfs_agencies", column: "agency_id"
    add_foreign_key "route_stops", "gtfs_routes", column: "route_id"
    add_foreign_key "route_stops", "gtfs_stops", column: "stop_id"
  end
end
