# == Schema Information
#
# Table name: gtfs_stop_times
#
#  id                       :integer          not null, primary key
#  stop_sequence            :integer          not null
#  stop_headsign            :string
#  pickup_type              :integer
#  drop_off_type            :integer
#  shape_dist_traveled      :float
#  timepoint                :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  feed_version_id          :integer          not null
#  trip_id                  :integer          not null
#  stop_id                  :integer          not null
#  destination_id           :integer
#  arrival_time             :integer          not null
#  departure_time           :integer          not null
#  destination_arrival_time :integer
#
# Indexes
#
#  index_gtfs_stop_times_on_arrival_time              (arrival_time)
#  index_gtfs_stop_times_on_departure_time            (departure_time)
#  index_gtfs_stop_times_on_destination_arrival_time  (destination_arrival_time)
#  index_gtfs_stop_times_on_destination_id            (destination_id)
#  index_gtfs_stop_times_on_feed_version_id           (feed_version_id)
#  index_gtfs_stop_times_on_stop_headsign             (stop_headsign)
#  index_gtfs_stop_times_on_stop_id                   (stop_id)
#  index_gtfs_stop_times_on_stop_sequence             (stop_sequence)
#  index_gtfs_stop_times_on_trip_id                   (trip_id)
#  index_gtfs_stop_times_unique                       (feed_version_id,trip_id,stop_sequence) UNIQUE
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
