# == Schema Information
#
# Table name: gtfs_stops
#
#  id                  :integer          not null, primary key
#  stop_id             :string           not null
#  stop_code           :string           not null
#  stop_name           :string           not null
#  stop_desc           :string           not null
#  zone_id             :string           not null
#  stop_url            :string           not null
#  location_type       :integer          not null
#  stop_timezone       :string           not null
#  wheelchair_boarding :integer          not null
#  geometry            :geography({:srid not null, point, 4326
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  feed_version_id     :integer          not null
#  parent_station      :integer
#  level_id            :integer
#
# Indexes
#
#  index_gtfs_stops_on_geometry        (geometry) USING gist
#  index_gtfs_stops_on_location_type   (location_type)
#  index_gtfs_stops_on_parent_station  (parent_station)
#  index_gtfs_stops_on_stop_code       (stop_code)
#  index_gtfs_stops_on_stop_desc       (stop_desc)
#  index_gtfs_stops_on_stop_id         (stop_id)
#  index_gtfs_stops_on_stop_name       (stop_name)
#  index_gtfs_stops_unique             (feed_version_id,stop_id) UNIQUE
#

class GTFSStopSerializer < GTFSEntitySerializer
    attributes :stop_id,
                :stop_code,
                :stop_name,
                :stop_desc,
                :stop_lat,
                :stop_lon,
                :zone_id,
                :stop_url,
                :location_type,
                :stop_timezone,
                :wheelchair_boarding,
                :parent_station_id
end
  
