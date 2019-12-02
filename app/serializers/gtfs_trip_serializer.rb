# == Schema Information
#
# Table name: gtfs_trips
#
#  id                    :integer          not null, primary key
#  trip_id               :string           not null
#  trip_headsign         :string           not null
#  trip_short_name       :string           not null
#  direction_id          :integer          not null
#  block_id              :string           not null
#  wheelchair_accessible :integer          not null
#  bikes_allowed         :integer          not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  feed_version_id       :integer          not null
#  route_id              :integer          not null
#  shape_id              :integer
#  stop_pattern_id       :integer          not null
#  service_id            :integer          not null
#
# Indexes
#
#  index_gtfs_trips_on_route_id         (route_id)
#  index_gtfs_trips_on_service_id       (service_id)
#  index_gtfs_trips_on_shape_id         (shape_id)
#  index_gtfs_trips_on_trip_headsign    (trip_headsign)
#  index_gtfs_trips_on_trip_id          (trip_id)
#  index_gtfs_trips_on_trip_short_name  (trip_short_name)
#  index_gtfs_trips_unique              (feed_version_id,trip_id) UNIQUE
#

class GTFSTripSerializer < GTFSEntitySerializer
    attributes :service_id,
                :trip_id,
                :trip_headsign,
                :trip_short_name,
                :direction_id,
                :block_id,
                :wheelchair_accessible,
                :bikes_allowed,
                :route_id,
                :shape_id
    
    attribute :service
end
  
