class HarmonizeGTFS < ActiveRecord::Migration
  def change
    rename_column :gtfs_stops, :parent_station_id, :parent_station
    add_column :gtfs_stops, :level_id, :string
    add_column :gtfs_trips, :stop_pattern_id, :int
    add_column :gtfs_calendars, :generated, :bool
    add_column :gtfs_feed_infos, :feed_version, :string
    remove_column :gtfs_fare_attributes, :transfers
    add_column :gtfs_fare_attributes, :transfers, :string
  end
end
