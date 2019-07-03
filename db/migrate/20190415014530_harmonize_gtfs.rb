class HarmonizeGTFS < ActiveRecord::Migration
  def change
    add_column :feed_versions, :deleted_at, :datetime

    ["old", "current"].each { |a| 
      add_column "#{a}_feeds", :deleted_at, :datetime
      add_column "#{a}_feeds", :license, :hstore
      add_column "#{a}_feeds", :other_ids, :hstore
      add_column "#{a}_feeds", :associated_feeds, :string, array: true
      add_column "#{a}_feeds", :languages, :string, array: true
      add_column "#{a}_feeds", :feed_namespace_id, :string
    }
    ###########
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
    # add_foreng_key :gtfs_stops, :gtfs_stops

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

  end
end
