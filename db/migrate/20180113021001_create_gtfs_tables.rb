class CreateGTFSTables < ActiveRecord::Migration
  def change
    create_table :gtfs_agencies do |t|
      t.string :agency_id, index: true
      t.string :agency_name, index: true, null: false
      t.string :agency_url, null: false
      t.string :agency_timezone, null: false
      t.string :agency_lang
      t.string :agency_phone
      t.string :agency_fare_url
      t.string :agency_email
      #
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :entity, references: :current_operators, index: true
    end
    add_index :gtfs_agencies, [:feed_version_id, :agency_id], unique: true, name: 'index_gtfs_agencies_unique'

    create_table :gtfs_stops do |t|
      t.string :stop_id, null: false, index: true
      t.string :stop_code, index: true
      t.string :stop_name, null: false, index: true
      t.string :stop_desc, index: true
      # t.float :stop_lat
      # t.float :stop_lon
      t.string :zone_id
      t.string :stop_url
      t.integer :location_type, index: true
      # t.string :parent_station
      t.string :stop_timezone
      t.integer :wheelchair_boarding
      #
      t.st_point :geometry, null: false, geographic: true
      t.index :geometry, using: :gist
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :entity, references: :current_stops, index: true
      t.references :parent_station, references: :gtfs_stops, index: true
    end
    add_index :gtfs_stops, [:feed_version_id, :stop_id], unique: true, name: 'index_gtfs_stops_unique'

    create_table :gtfs_routes do |t|
      t.string :route_id, index: true, null: false
      # t.string :agency_id
      t.string :route_short_name, null: false, index: true
      t.string :route_long_name, null: false, index: true
      t.string :route_desc, index: true
      t.integer :route_type, null: false, index: true
      t.string :route_url
      t.string :route_color
      t.string :route_text_color
      #
      t.multi_line_string :geometry, geographic: true
      t.multi_line_string :geometry_generated, geographic: true
      t.index :geometry, using: :gist
      t.index :geometry_generated, using: :gist
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :entity, references: :current_routes, index: true
      t.references :agency, references: :gtfs_agencies, null: false, index: true
    end
    add_index :gtfs_routes, [:feed_version_id, :route_id], unique: true, name: 'index_gtfs_routes_unique'

    create_table :gtfs_trips do |t|
      # t.string :route_id
      t.string :service_id, null: false, index: true
      t.string :trip_id, index: true, null: false
      t.string :trip_headsign, index: true
      t.string :trip_short_name, index: true
      t.integer :direction_id
      t.string :block_id
      # t.string :shape_id
      t.integer :wheelchair_accessible
      t.integer :bikes_allowed
      #
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :entity, references: :current_route_stop_patterns, index: true
      t.references :route, references: :gtfs_routes, null: false, index: true
      t.references :shape, references: :gtfs_shapes, index: true
    end
    add_index :gtfs_trips, [:feed_version_id, :trip_id], unique: true, name: 'index_gtfs_trips_unique'

    create_table :gtfs_stop_times, id: :bigserial do |t|
      # t.string :trip_id
      # t.string :arrival_time
      # t.string :departure_time
      # t.string :stop_id
      t.integer :stop_sequence, null: false
      t.string :stop_headsign
      t.integer :pickup_type
      t.integer :drop_off_type
      t.float :shape_dist_traveled
      t.integer :timepoint
      #
      t.boolean :interpolated, default: false, null: false
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :trip, references: :gtfs_trips, index: true, null: false
      t.references :stop, references: :gtfs_stops, index: true, null: false
      t.references :destination, references: :gtfs_stops, index: true # null: false
      t.integer :arrival_time, index: true, null: false
      t.integer :departure_time, index: true, null: false
      t.integer :destination_arrival_time, index: true # null: false
    end
    add_index :gtfs_stop_times, [:feed_version_id, :trip_id, :stop_sequence], unique: true, name: 'index_gtfs_stop_times_unique'

    create_table :gtfs_calendars do |t|
      t.string :service_id, index: true, null: false
      t.boolean :monday, null: false, index: true
      t.boolean :tuesday, null: false, index: true
      t.boolean :wednesday, null: false, index: true
      t.boolean :thursday, null: false, index: true
      t.boolean :friday, null: false, index: true
      t.boolean :saturday, null: false, index: true
      t.boolean :sunday, null: false, index: true
      t.date :start_date, null: false, index: true
      t.date :end_date, null: false, index: true
      t.timestamps null: false
      #
      t.references :feed_version, index: true, null: false
    end
    add_index :gtfs_calendars, [:feed_version_id, :service_id], unique: true

    create_table :gtfs_calendar_dates do |t|
      t.string :service_id, index: true, null: false
      t.date :date, index: true, null: false
      t.integer :exception_type, null: false, index: true
      #
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
    end
    add_index :gtfs_calendar_dates, [:feed_version_id, :service_id, :date], unique: true, name: 'index_gtfs_calendar_dates_unique'

    create_table :gtfs_fare_attributes do |t|
      t.string :fare_id, index: true, null: false
      t.float :price, null: false
      t.string :currency_type, null: false
      t.integer :payment_method, null: false
      t.integer :transfers #, null: false
      # t.string :agency_id
      t.integer :transfer_duration
      #
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :agency, references: :gtfs_agencies, index: true
    end
    add_index :gtfs_fare_attributes, [:feed_version_id, :fare_id], unique: true, name: 'index_gtfs_fare_attributes_unique'

    create_table :gtfs_fare_rules do |t|
      t.string :fare_id, index: true, null: false
      # t.string :route_id
      # t.string :origin_id
      # t.string :destination_id
      t.string :contains_id
      #
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :route, references: :gtfs_routes, index: true
      t.references :origin, references: :gtfs_stops, index: true
      t.references :destination, references: :gtfs_stops, index: true
    end

    create_table :gtfs_shapes do |t|
      t.string :shape_id, index: true, null: false
      # t.float :shape_pt_lat
      # t.float :shape_pt_lon
      # t.integer :shape_pt_sequence
      # f.float :shape_dist_traveled
      t.boolean :generated, default: false, null: false, index: true
      t.line_string :geometry, null: false, geographic: true, has_m: true
      t.index :geometry, using: :gist
      #
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
    end
    add_index :gtfs_shapes, [:feed_version_id, :shape_id], unique: true, name: 'index_gtfs_shapes_unique'

    create_table :gtfs_frequencies do |t|
      # t.string :trip_id
      t.integer :start_time, null: false
      t.integer :end_time, null: false
      t.integer :headway_secs, null: false
      t.integer :exact_times
      t.timestamps null: false
      #
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :trip, references: :gtfs_trip, null: false, index: true
    end

    create_table :gtfs_transfers do |t|
      # t.string :from_stop_id
      # t.string :to_stop_id
      t.integer :transfer_type #, null: false
      t.integer :min_transfer_time
      #
      t.timestamps null: false
      t.references :feed_version, index: true, null: false
      t.references :from_stop, references: :gtfs_stop, null: false, index: true
      t.references :to_stop, references: :gtfs_stop, null: false, index: true
    end

    create_table :gtfs_feed_infos do |t|
      t.string :feed_publisher_name, null: false
      t.string :feed_publisher_url, null: false
      t.string :feed_lang, null: false
      t.date :feed_start_date
      t.date :feed_end_date
      t.string :feed_version_name
      #
      t.timestamps null: false
      t.references :feed_version, null: false, index: true
    end
    add_index :gtfs_feed_infos, [:feed_version_id], unique: true, name: 'index_gtfs_feed_info_unique'
  end
end
