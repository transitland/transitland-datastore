# == Schema Information
#
# Table name: gtfs_stops
#
#  id                  :integer          not null, primary key
#  stop_id             :string           not null
#  stop_code           :string
#  stop_name           :string           not null
#  stop_desc           :string
#  zone_id             :string
#  stop_url            :string
#  location_type       :integer
#  stop_timezone       :string
#  wheelchair_boarding :integer
#  geometry            :geography({:srid not null, point, 4326
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  feed_version_id     :integer          not null
#  entity_id           :integer
#  parent_station_id   :integer
#
# Indexes
#
#  index_gtfs_stops_on_entity_id          (entity_id)
#  index_gtfs_stops_on_feed_version_id    (feed_version_id)
#  index_gtfs_stops_on_geometry           (geometry) USING gist
#  index_gtfs_stops_on_location_type      (location_type)
#  index_gtfs_stops_on_parent_station_id  (parent_station_id)
#  index_gtfs_stops_on_stop_code          (stop_code)
#  index_gtfs_stops_on_stop_desc          (stop_desc)
#  index_gtfs_stops_on_stop_id            (stop_id)
#  index_gtfs_stops_on_stop_name          (stop_name)
#  index_gtfs_stops_unique                (feed_version_id,stop_id) UNIQUE
#

class GTFSStopSerializer < GTFSEntitySerializer
    attributes :stop_id,
                :stop_code,
                :stop_name,
                :stop_desc,
                :zone_id,
                :stop_url,
                :location_type,
                :stop_timezone,
                :wheelchair_boarding,
                :parent_station_id
end
  
