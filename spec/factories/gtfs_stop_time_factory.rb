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

FactoryGirl.define do
    factory :gtfs_stop_time do
        stop_sequence 1
        stop_headsign 'Test Stop Time'
        pickup_type 0
        drop_off_type 0
        shape_dist_traveled 0.0
        timepoint 0
        origin_arrival_time 0
        origin_departure_time 10
        destination_arrival_time 60
        association :trip, factory: :gtfs_trip
        association :origin, factory: :gtfs_stop
        association :destination, factory: :gtfs_stop
        association :feed_version
    end
end  
