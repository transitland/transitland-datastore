def change_null(table, col, nullable, default=nil)
  if !default.nil?
    change_column_default table, col, default
  end
  change_column_null table, col, nullable, default
end

class HarmonizeGTFS < ActiveRecord::Migration
  def change
    ["old", "current"].each { |a| 
      change_column "#{a}_feeds", :urls, 'JSONB USING hstore_to_json(urls)'
      change_column "#{a}_feeds", :authorization, 'JSONB USING hstore_to_json("authorization")'
      rename_column "#{a}_feeds", :feed_format, :spec
      rename_column "#{a}_feeds", :authorization, :auth
      # add cols
      add_column "#{a}_feeds", :deleted_at, :datetime
      add_column "#{a}_feeds", :last_successful_fetch_at, :datetime
      add_column "#{a}_feeds", :last_fetch_error, :string
      add_column "#{a}_feeds", :license, :jsonb
      add_column "#{a}_feeds", :other_ids, :jsonb
      add_column "#{a}_feeds", :associated_feeds, :jsonb
      add_column "#{a}_feeds", :languages, :jsonb
      add_column "#{a}_feeds", :feed_namespace_id, :string
      # without defaults
      change_null "#{a}_feeds", :onestop_id, false
      change_null "#{a}_feeds", :created_at, false
      change_null "#{a}_feeds", :updated_at, false
      # with defaults
      change_null "#{a}_feeds", :last_fetch_error, false, ""
      change_null "#{a}_feeds", :feed_namespace_id, false, ""
      change_null "#{a}_feeds", :spec, false, "gtfs"
      # change_null "#{a}_feeds", :url, false, ""
      change_null "#{a}_feeds", :urls, false, {}
      change_null "#{a}_feeds", :auth, false, {}
      change_null "#{a}_feeds", :license, false, {}
      change_null "#{a}_feeds", :associated_feeds, false, {}
      change_null "#{a}_feeds", :languages, false, {}
      change_null "#{a}_feeds", :other_ids, false, {}
    }

    Feed.where('').find_each do |feed|
      license = {
        spdx_identifier: feed.attributes["license_name"],
        url: feed.attributes["license_url"],
        use_without_attribution: feed.attributes["license_use_without_attribution"],
        create_derived_product: feed.attributes["license_create_derived_product"],
        redistributionn_allowed: feed.attributes["license_redistribute"],
        attribution_test: feed.attributes["license_attribution_text"]  
      }.compact
      feed.update_attribute("license", license)
    end

    ["old", "current"].each { |a| 
      remove_column "#{a}_feeds", :license_name
      remove_column "#{a}_feeds", :license_url
      remove_column "#{a}_feeds", :license_use_without_attribution
      remove_column "#{a}_feeds", :license_create_derived_product
      remove_column "#{a}_feeds", :license_redistribute
      remove_column "#{a}_feeds", :license_attribution_text
    }

    ##################

    # add cols
    add_column :feed_versions, :deleted_at, :datetime
    add_column :feed_versions, :sha1_dir, :string
    # without defaults
    change_null :feed_versions, :feed_id, false
    change_null :feed_versions, :earliest_calendar_date, false
    change_null :feed_versions, :latest_calendar_date, false
    change_null :feed_versions, :sha1, false
    change_null :feed_versions, :fetched_at, false
    change_null :feed_versions, :created_at, false
    change_null :feed_versions, :updated_at, false
    # with defaults
    change_null :feed_versions, :url, false, ""
    change_null :feed_versions, :file, false, ""
    change_null :feed_versions, :feed_type, false, "gtfs"
    change_null :feed_versions, :import_level, false, 0
    # remove_column :feed_versions, :md5
    # remove_column :feed_versions, :md5_raw

    # gtfs_imports
    rename_table :gtfs_imports, :feed_version_gtfs_imports 
    add_column :feed_version_gtfs_imports, :in_progress, :bool
    remove_index :feed_version_gtfs_imports, :feed_version_id
    add_index :feed_version_gtfs_imports, :feed_version_id, unique: true
    add_foreign_key :feed_version_gtfs_imports, :feed_versions
    # without default
    change_null :feed_version_gtfs_imports, :succeeded, false
    change_null :feed_version_gtfs_imports, :import_log, false
    change_null :feed_version_gtfs_imports, :import_level, false
    change_null :feed_version_gtfs_imports, :exception_log, false
    change_null :feed_version_gtfs_imports, :in_progress, false, false

    ##### GTFS entities #####

    rename_column :gtfs_stops, :parent_station_id, :parent_station
    add_column :gtfs_stops, :level_id, :string
    add_column :gtfs_trips, :stop_pattern_id, :int
    add_column :gtfs_calendars, :generated, :bool
    add_column :gtfs_feed_infos, :feed_version, :string
    remove_column :gtfs_fare_attributes, :transfers
    add_column :gtfs_fare_attributes, :transfers, :integer

    remove_column :gtfs_agencies, :entity_id
    remove_column :gtfs_stops, :entity_id
    remove_column :gtfs_routes, :entity_id
    remove_column :gtfs_trips, :entity_id

    change_column :gtfs_calendars, :monday, :integer, :using => 'case when monday then 1 else 0 end'
    change_column :gtfs_calendars, :tuesday, :integer, :using => 'case when tuesday then 1 else 0 end'
    change_column :gtfs_calendars, :wednesday, :integer, :using => 'case when wednesday then 1 else 0 end'
    change_column :gtfs_calendars, :thursday, :integer, :using => 'case when thursday then 1 else 0 end'
    change_column :gtfs_calendars, :friday, :integer, :using => 'case when friday then 1 else 0 end'
    change_column :gtfs_calendars, :saturday, :integer, :using => 'case when saturday then 1 else 0 end'
    change_column :gtfs_calendars, :sunday, :integer, :using => 'case when sunday then 1 else 0 end'

    remove_column :gtfs_calendar_dates, :service_id
    add_column :gtfs_calendar_dates, :service_id, :integer
    add_index :gtfs_calendar_dates, :service_id

    remove_column :gtfs_trips, :service_id
    add_column :gtfs_trips, :service_id, :integer
    add_index :gtfs_trips, :service_id    

    remove_column :gtfs_fare_rules, :fare_id
    add_column :gtfs_fare_rules, :fare_id, :integer
    add_index :gtfs_fare_rules, :fare_id 

    ###############

    add_foreign_key :gtfs_agencies, :feed_versions

    add_foreign_key :gtfs_trips, :feed_versions
    add_foreign_key :gtfs_trips, :gtfs_routes, column: :route_id
    add_foreign_key :gtfs_trips, :gtfs_calendars, column: :service_id

    add_foreign_key :gtfs_calendars, :feed_versions
  
    add_foreign_key :gtfs_calendar_dates, :feed_versions
    add_foreign_key :gtfs_calendar_dates, :gtfs_calendars, column: :service_id

    add_foreign_key :gtfs_routes, :feed_versions
    add_foreign_key :gtfs_routes, :gtfs_agencies, column: :agency_id

    add_foreign_key :gtfs_stops, :feed_versions
    # add_foreign_key :gtfs_stops, :gtfs_stops

    add_foreign_key :gtfs_stop_times, :feed_versions
    add_foreign_key :gtfs_stop_times, :gtfs_stops, column: :stop_id
    add_foreign_key :gtfs_stop_times, :gtfs_trips, column: :trip_id

    add_foreign_key :gtfs_fare_attributes, :feed_versions

    add_foreign_key :gtfs_fare_rules, :feed_versions
    add_foreign_key :gtfs_fare_rules, :gtfs_fare_attributes, column: :fare_id

    add_foreign_key :gtfs_transfers, :feed_versions
    add_foreign_key :gtfs_transfers, :gtfs_stops, column: :from_stop_id
    add_foreign_key :gtfs_transfers, :gtfs_stops, column: :to_stop_id

    add_foreign_key :gtfs_feed_infos, :feed_versions

    add_foreign_key :gtfs_frequencies, :feed_versions
    add_foreign_key :gtfs_frequencies, :gtfs_trips, column: :trip_id

    ############
    # make more GTFS related columns NOT NULL to make life easier
    change_column_null :gtfs_agencies, :agency_id, false
    change_column_null :gtfs_agencies, :agency_lang, false
    change_column_null :gtfs_agencies, :agency_phone, false
    change_column_null :gtfs_agencies, :agency_fare_url, false
    change_column_null :gtfs_agencies, :agency_email, false

    change_column_null :gtfs_calendar_dates, :service_id, false

    change_column_null :gtfs_calendars, :generated, false

    change_column_null :gtfs_fare_attributes, :transfer_duration, false
    change_column_null :gtfs_fare_attributes, :transfers, false
    change_column_null :gtfs_fare_attributes, :agency_id, true

    change_column_null :gtfs_fare_rules, :origin_id, false
    change_column_null :gtfs_fare_rules, :destination_id, false
    change_column_null :gtfs_fare_rules, :contains_id, false
    # route_id?
    # fare_id?

    change_column_null :gtfs_feed_infos, :feed_version_name, false, default: ""
    remove_column :gtfs_feed_infos, :feed_version
    # change_column_null :gtfs_feed_infos, :feed_start_date, false
    # change_column_null :gtfs_feed_infos, :feed_end_date, false

    change_column_null :gtfs_frequencies, :exact_times, false

    change_column_null :gtfs_routes, :route_url, false
    change_column_null :gtfs_routes, :route_desc, false
    change_column_null :gtfs_routes, :route_color, false
    change_column_null :gtfs_routes, :route_text_color, false
    change_column_null :gtfs_routes, :route_sort_order, false
    remove_column :gtfs_routes, :geometry
    remove_column :gtfs_routes, :geometry_generated
    
    change_column_null :gtfs_stop_times, :stop_headsign, false
    change_column_null :gtfs_stop_times, :pickup_type, false
    change_column_null :gtfs_stop_times, :drop_off_type, false
    change_column_null :gtfs_stop_times, :shape_dist_traveled, false
    change_column_null :gtfs_stop_times, :timepoint, false
    remove_column :gtfs_stop_times, :destination_id
    remove_column :gtfs_stop_times, :destination_arrival_time

    change_column_null :gtfs_stops, :stop_code, false
    change_column_null :gtfs_stops, :stop_desc, false
    change_column_null :gtfs_stops, :zone_id, false
    change_column_null :gtfs_stops, :stop_url, false
    change_column_null :gtfs_stops, :location_type, false
    change_column_null :gtfs_stops, :stop_timezone, false
    change_column_null :gtfs_stops, :wheelchair_boarding, false
    change_column_null :gtfs_stops, :level_id, false

    change_column_null :gtfs_transfers, :min_transfer_time, false

    change_column_null :gtfs_trips, :trip_headsign, false
    change_column_null :gtfs_trips, :trip_short_name, false
    change_column_null :gtfs_trips, :direction_id, false
    change_column_null :gtfs_trips, :block_id, false
    change_column_null :gtfs_trips, :wheelchair_accessible, false
    change_column_null :gtfs_trips, :bikes_allowed, false
    change_column_null :gtfs_trips, :stop_pattern_id, false
    change_column_null :gtfs_trips, :service_id, false    
    change_column_null :gtfs_trips, :shape_id, true
  end
end
