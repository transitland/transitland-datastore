class ActiveEntities < ActiveRecord::Migration
  def change

    ########

    create_table :active_stops, id: false do |t|
      t.bigint   "id", null: false
      t.bigint   "feed_version_id",                                                                 null: false
      t.bigint   "parent_station"
      #
      t.string    "stop_id",                                                                         null: false
      t.string    "stop_code",                                                                       null: false
      t.string    "stop_name",                                                                       null: false
      t.string    "stop_desc",                                                                       null: false
      t.string    "zone_id",                                                                         null: false
      t.string    "stop_url",                                                                        null: false
      t.integer   "location_type",                                                                   null: false
      t.string    "stop_timezone",                                                                   null: false
      t.integer   "wheelchair_boarding",                                                             null: false
      t.geography "geometry",            limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
      t.datetime  "created_at",                                                                      null: false
      t.datetime  "updated_at",                                                                      null: false
      t.string    "level_id",                                                                        null: false  
    end
    add_index "active_stops", ["id"], name: "index_active_stops_unique", unique: true, using: :btree
    add_index "active_stops", ["feed_version_id"], name: "index_active_stops_on_feed_version_id", using: :btree
    add_index "active_stops", ["geometry"], name: "index_active_stops_on_geometry", using: :gist
    add_index "active_stops", ["location_type"], name: "index_active_stops_on_location_type", using: :btree
    add_index "active_stops", ["parent_station"], name: "index_active_stops_on_parent_station", using: :btree
    add_index "active_stops", ["stop_id"], name: "index_active_stops_on_stop_id", using: :btree
    add_index "active_stops", ["stop_name"], name: "index_active_stops_on_stop_name", using: :btree
    add_foreign_key :active_stops, :gtfs_stops, column: :id
    add_foreign_key :active_stops, :gtfs_stops, column: :parent_station
    add_foreign_key :active_stops, :feed_versions, column: :feed_version_id

    create_table "active_routes", id: false do |t|
      t.bigint  "id", null: false
      t.bigint  "feed_version_id",  null: false
      t.bigint  "agency_id",        null: false
      #
      t.string   "route_id",         null: false
      t.string   "route_short_name", null: false
      t.string   "route_long_name",  null: false
      t.string   "route_desc",       null: false
      t.integer  "route_type",       null: false
      t.string   "route_url",        null: false
      t.string   "route_color",      null: false
      t.string   "route_text_color", null: false
      t.integer  "route_sort_order", null: false
      t.datetime "created_at",       null: false
      t.datetime "updated_at",       null: false
      ###
      t.geography "geometry",            limit: {:srid=>4326, :type=>"line_string", :geographic=>true}
      t.geography "geometry_z14",            limit: {:srid=>4326, :type=>"line_string", :geographic=>true}
      t.geography "geometry_z10",            limit: {:srid=>4326, :type=>"line_string", :geographic=>true}
      t.geography "geometry_z6",            limit: {:srid=>4326, :type=>"line_string", :geographic=>true}
      t.geography "centroid",            limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    end
    add_index "active_routes", ["id"], name: "index_active_routes_unique", unique: true, using: :btree
    add_index "active_routes", ["agency_id"], name: "index_active_routes_on_agency_id", using: :btree
    add_index "active_routes", ["feed_version_id"], name: "index_active_routes_on_feed_version_id", using: :btree
    add_index "active_routes", ["route_id"], name: "index_active_routes_on_route_id", using: :btree
    add_index "active_routes", ["route_long_name"], name: "index_active_routes_on_route_long_name", using: :btree
    add_index "active_routes", ["route_short_name"], name: "index_active_routes_on_route_short_name", using: :btree
    add_index "active_routes", ["route_type"], name: "index_active_routes_on_route_type", using: :btree
    add_index "active_routes", ["geometry"], name: "index_active_routes_on_geometry", using: :gist
    add_index "active_routes", ["centroid"], name: "index_active_routes_on_centroid", using: :gist
    add_foreign_key :active_routes, :gtfs_routes, column: :id
    add_foreign_key :active_routes, :gtfs_agencies, column: :agency_id
    add_foreign_key :active_routes, :feed_versions, column: :feed_version_id

    create_table "active_agencies", id: false do |t|
      t.bigint  "id", null: false
      t.bigint  "feed_version_id", null: false
      #
      t.string   "agency_id",       null: false
      t.string   "agency_name",     null: false
      t.string   "agency_url",      null: false
      t.string   "agency_timezone", null: false
      t.string   "agency_lang",     null: false
      t.string   "agency_phone",    null: false
      t.string   "agency_fare_url", null: false
      t.string   "agency_email",    null: false
      t.datetime "created_at",      null: false
      t.datetime "updated_at",      null: false
      ###
      t.geography "geometry",            limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
      t.geography "centroid",            limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    end  
    add_index "active_agencies", ["id"], name: "index_active_agencies_unique", unique: true, using: :btree    
    add_index "active_agencies", ["agency_id"], name: "index_active_agencies_on_agency_id", using: :btree
    add_index "active_agencies", ["agency_name"], name: "index_active_agencies_on_agency_name", using: :btree
    add_index "active_agencies", ["feed_version_id"], name: "index_active_agencies_on_feed_version_id", using: :btree
    add_index "active_agencies", ["geometry"], name: "index_active_agencies_on_geometry", using: :gist
    add_index "active_agencies", ["centroid"], name: "index_active_agencies_on_centroid", using: :gist
    add_foreign_key :active_agencies, :gtfs_agencies, column: :id
    add_foreign_key :active_agencies, :feed_versions, column: :feed_version_id

    ######################

    create_table "route_stops", id: false do |t|
      t.bigint "feed_version_id", null: false
      t.bigint "agency_id", null: false
      t.bigint "route_id", null: false
      t.bigint "stop_id", null: false
    end
    add_index "route_stops", ["feed_version_id"], name: "index_route_stops_on_feed_version_id", using: :btree
    add_index "route_stops", ["agency_id"], name: "index_route_stops_on_agency_id", using: :btree
    add_index "route_stops", ["route_id"], name: "index_route_stops_on_route_id", using: :btree
    add_index "route_stops", ["stop_id"], name: "index_route_stops_on_stop_id", using: :btree
    add_foreign_key :route_stops, :feed_versions, column: :feed_version_id
    add_foreign_key :route_stops, :gtfs_agencies, column: :agency_id
    add_foreign_key :route_stops, :gtfs_routes, column: :route_id
    add_foreign_key :route_stops, :gtfs_stops, column: :stop_id

    ###

    create_table "feed_version_geometries", id: false do |t|
      t.bigint "feed_version_id", null: false
      t.geography "geometry",            limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
      t.geography "centroid",            limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    end
    add_index "feed_version_geometries", ["feed_version_id"], name: "index_feed_version_geometries_unique", unique: true, using: :btree
    add_index "feed_version_geometries", ["geometry"], name: "index_feed_version_geometries_on_geometry", using: :gist
    add_index "feed_version_geometries", ["centroid"], name: "index_feed_version_geometries_on_centroid", using: :gist
    add_foreign_key :feed_version_geometries, :feed_versions, column: :feed_version_id

    ###

    create_table "agency_geometries", id: false do |t|
      t.bigint "agency_id", null: false
      t.bigint "feed_version_id", null: false
      t.geography "geometry",            limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
      t.geography "centroid",            limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    end
    add_index "agency_geometries", ["agency_id"], name: "index_agency_geometries_unique", unique: true, using: :btree
    add_index "agency_geometries", ["feed_version_id"], name: "index_agency_geometries_on_feed_version_id", using: :btree
    add_index "agency_geometries", ["geometry"], name: "index_agency_geometries_on_geometry", using: :gist
    add_index "agency_geometries", ["centroid"], name: "index_agency_geometries_on_centroid", using: :gist
    add_foreign_key :agency_geometries, :gtfs_agencies, column: :agency_id
    add_foreign_key :agency_geometries, :feed_versions, column: :feed_version_id

    ###

    create_table "route_geometries", id: false do |t|
      t.bigint "route_id", null: false
      t.bigint "feed_version_id", null: false
      t.bigint "shape_id", null: false
      t.integer "direction_id", null: false
      t.boolean "generated", null: false
      t.geography "geometry",            limit: {:srid=>4326, :type=>"line_string", :geographic=>true}, null: false
      t.geography "geometry_z14",            limit: {:srid=>4326, :type=>"line_string", :geographic=>true}, null: false
      t.geography "geometry_z10",            limit: {:srid=>4326, :type=>"line_string", :geographic=>true}, null: false
      t.geography "geometry_z6",            limit: {:srid=>4326, :type=>"line_string", :geographic=>true}, null: false
      t.geography "centroid",            limit: {:srid=>4326, :type=>"st_point", :geographic=>true}, null: false
    end
    add_index "route_geometries", ["route_id","direction_id"], name: "index_route_geometries_unique", unique: true, using: :btree
    add_index "route_geometries", ["feed_version_id"], name: "index_route_geometries_on_feed_version_id", using: :btree
    add_index "route_geometries", ["shape_id"], name: "index_route_geometries_on_shape_id", using: :btree
    add_index "route_geometries", ["geometry"], name: "index_route_geometries_on_geometry", using: :gist
    add_index "route_geometries", ["centroid"], name: "index_route_geometries_on_centroid", using: :gist
    add_foreign_key :route_geometries, :gtfs_routes, column: :route_id
    add_foreign_key :route_geometries, :gtfs_shapes, column: :shape_id
    add_foreign_key :route_geometries, :feed_versions, column: :feed_version_id

    #########

    # redundant indexes
    remove_index :gtfs_shapes, :feed_version_id
    remove_index :gtfs_agencies, :feed_version_id
    remove_index :gtfs_routes, :feed_version_id
    remove_index :gtfs_trips, :feed_version_id
    remove_index :gtfs_calendars, :feed_version_id
    remove_index :gtfs_stops, :feed_version_id
    remove_index :gtfs_fare_attributes, :feed_version_id
    remove_index :gtfs_stop_times, :feed_version_id
    remove_index :gtfs_feed_infos, :feed_version_id

    # unneeded indexes
    remove_index :gtfs_stop_times, :arrival_time
    remove_index :gtfs_stop_times, :departure_time

    # covering indexes
    add_index :gtfs_routes, ["feed_version_id", "id", "agency_id"], name: "index_gtfs_routes_on_feed_version_id_agency_id", using: :btree
    add_index :gtfs_stop_times, ["feed_version_id", "trip_id", "stop_id"], name: "index_gtfs_stop_times_on_feed_version_id_trip_id_stop_id", using: :btree

    ####

    remove_column :feed_states, :geometry


  end
end
