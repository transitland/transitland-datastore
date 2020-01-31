class AdditionalDerivedTables < ActiveRecord::Migration
  def change
    add_foreign_key "gtfs_shapes", "feed_versions", column: "feed_version_id"

    create_table :route_headways, id: :bigserial do |t|
      t.bigint :feed_version_id, null: false
      t.bigint :route_id, null: false
      t.bigint :selected_stop_id, null: false
      t.bigint :service_id, null: false
      t.integer :direction_id
      t.integer :headway_secs
    end
    add_index "route_headways", ["feed_version_id"], name: "route_headways_feed_version_id_idx", using: :btree
    add_index "route_headways", ["route_id"], name: "route_headways_route_id_idx", unique: true, using: :btree
    add_foreign_key "route_headways", "feed_versions", column: "feed_version_id"
    add_foreign_key "route_headways", "gtfs_routes", column: "route_id"
    add_foreign_key "route_headways", "gtfs_stops", column: "selected_stop_id"
    add_foreign_key "route_headways", "gtfs_calendars", column: "service_id"

    create_table :agency_places, id: :bigserial do |t|
      t.bigint :feed_version_id, null: false
      t.bigint :agency_id, null: false
      t.integer :count, null: false
      t.float :rank, null: false
      t.string :name
      t.string :adm1name, null: false
      t.string :adm0name, null: false
    end
    add_index "agency_places", ["feed_version_id"], name: "agency_places_feed_version_id_idx", using: :btree
    add_index "agency_places", ["agency_id"], name: "agency_places_agency_id_idx", using: :btree
    add_foreign_key "agency_places", "feed_versions", column: "feed_version_id"
    add_foreign_key "agency_places", "gtfs_agencies", column: "agency_id"

    drop_table :active_stops
    drop_table :active_agencies
    drop_table :active_routes

  end
end
