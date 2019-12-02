# == Schema Information
#
# Table name: gtfs_stop_times
#
#  id                  :integer          not null, primary key
#  arrival_time        :integer          not null
#  departure_time      :integer          not null
#  stop_sequence       :integer          not null
#  stop_headsign       :string           not null
#  pickup_type         :integer          not null
#  drop_off_type       :integer          not null
#  shape_dist_traveled :float            not null
#  timepoint           :integer          not null
#  interpolated        :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  feed_version_id     :integer          not null
#  trip_id             :integer          not null
#  stop_id             :integer          not null
#
# Indexes
#
#  index_gtfs_stop_times_on_feed_version_id_trip_id_stop_id  (feed_version_id,trip_id,stop_id)
#  index_gtfs_stop_times_on_stop_id                          (stop_id)
#  index_gtfs_stop_times_on_trip_id                          (trip_id)
#  index_gtfs_stop_times_unique                              (feed_version_id,trip_id,stop_sequence) UNIQUE
#

class GTFSStopTimeSerializer < GTFSEntitySerializer
    attributes :stop_sequence, 
                :stop_headsign, 
                :pickup_type, 
                :drop_off_type, 
                :shape_dist_traveled, 
                :timepoint, 
                :interpolated, 
                :trip_id, 
                :stop_id, 
                :destination_id,
                :arrival_time,
                :departure_time,
                :destination_arrival_time

    def arrival_time
        GTFS::WideTime.new(object.arrival_time).to_s
    end

    def departure_time
        GTFS::WideTime.new(object.departure_time).to_s
    end

    def destination_arrival_time
        GTFS::WideTime.new(object.destination_arrival_time).to_s if object.destination_arrival_time
    end
end
  
