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
#  origin_id                :integer          not null
#  destination_id           :integer
#  origin_arrival_time      :integer
#  origin_departure_time    :integer
#  destination_arrival_time :integer
#
# Indexes
#
#  index_gtfs_stop_times_on_destination_arrival_time  (destination_arrival_time)
#  index_gtfs_stop_times_on_destination_id            (destination_id)
#  index_gtfs_stop_times_on_feed_version_id           (feed_version_id)
#  index_gtfs_stop_times_on_origin_arrival_time       (origin_arrival_time)
#  index_gtfs_stop_times_on_origin_departure_time     (origin_departure_time)
#  index_gtfs_stop_times_on_origin_id                 (origin_id)
#  index_gtfs_stop_times_on_stop_headsign             (stop_headsign)
#  index_gtfs_stop_times_on_stop_sequence             (stop_sequence)
#  index_gtfs_stop_times_on_trip_id                   (trip_id)
#  index_gtfs_stop_times_unique                       (feed_version_id,trip_id,stop_sequence) UNIQUE
#

class GTFSStopTime < ActiveRecord::Base
  belongs_to :feed_version
  belongs_to :trip, class_name: 'GTFSTrip'
  belongs_to :origin, class_name: 'GTFSStop'
  belongs_to :destination, class_name: 'GTFSStop'
  belongs_to :trip, class_name: 'GTFSTrip'
  has_one :shape, :through => :trip

  def interpolate_stop_times(stop_times)
    # shape_id = GTFSTrip.find(stop_times.first.trip_id).shape_id
    # origins = []
    # stop_times.each do |st|
    #   origins << st.origin_id if SHAPE_STOP_DISTANCE[[st.origin_id, shape_id]].nil?
    # end
    # s = 'gtfs_stops.id, ST_LineLocatePoint(gtfs_shapes.geometry::geometry, ST_ClosestPoint(gtfs_shapes.geometry::geometry, ST_SetSRID(gtfs_stops.geometry, 4326))) AS line_s'
    # GTFSStop.where(id: origins).select(s).joins('INNER JOIN gtfs_shapes ON gtfs_shapes.id='+shape_id.to_s).each do |row|
    #   SHAPE_STOP_DISTANCE[[row.id, shape_id]] = row.line_s
    # end
    s = stop_times.size
    i = 0
    until i == s do
      st1 = stop_times[i]
      i += 1
      j = i
      ip = [st1]
      until j == s do
        st2 = stop_times[j]
        j += 1
        break if st2.origin_arrival_time
        ip << st2        
      end
    end
  end

end
