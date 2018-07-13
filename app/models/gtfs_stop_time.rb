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

  def self.interpolate_find_gaps(stop_times)
    gaps = []
    o, c = nil, nil
    stop_times.each_with_index do |st, i|
      # close an open gap
      puts "i: #{i} st: #{st.stop_sequence} origin: #{st.origin_id} arrival_time: #{st.origin_arrival_time} departure_time: #{st.origin_departure_time}"
      if o && st.origin_arrival_time
        gaps << [o, i] if (i-o > 1)
        o = nil
      end
      # open a new gap
      if o.nil? && st.origin_departure_time
        o = i
      end
    end
    return gaps
  end

  def self.interpolate_stop_times(stop_times)
    # Sort by stop_sequence
    stop_times.sort_by! { |st| st.stop_sequence }

    # If we only have 1 timepoint, assume it is both arrival and departure
    stop_times.each do |st|
      (st.origin_arrival_time = st.origin_departure_time) if st.origin_arrival_time.nil?
      (st.origin_departure_time = st.origin_arrival_time) if st.origin_departure_time.nil?
    end

    # These two values are required by spec
    fail Exception.new('missing first departure time') if stop_times.first.origin_departure_time.nil?
    fail Exception.new('missing last arrival time') if stop_times.last.origin_arrival_time.nil?

    # Return early if possible
    gaps = interpolate_find_gaps(stop_times)
    return stop_times if gaps.size == 0

    # Measure stops along line
    trip_id = stop_times.first.trip_id
    shape_id = GTFSTrip.find(trip_id).shape_id

    trip_pattern = stop_times.map(&:origin_id)
    s = 'SELECT 0 AS id, ST_MakeLine(geometry) AS geometry FROM (SELECT gtfs_stops.id, gtfs_stops.geometry, gtfs_stop_times.stop_sequence FROM gtfs_stops INNER JOIN gtfs_stop_times ON gtfs_stop_times.origin_id = gtfs_stops.id WHERE gtfs_stop_times.trip_id = 1 ORDER BY gtfs_stop_times.stop_sequence) as a'
    

    
    pattern_id = trip_id
    origins = []
    shape_stop_distance = {}
    stop_times.each do |st|
      origins << st.origin_id if shape_stop_distance[[st.origin_id, shape_id]].nil?
    end
    shape_id = nil
    
    # Create shape if necessary
    if origins && shape_id
      shape_join = 'INNER JOIN gtfs_shapes AS shapes ON true'
    elsif origins
      shape_id = 0
      shape_join = 'INNER JOIN (SELECT 0 as id, ST_SetSRID(ST_MakeLine(geometry), 4326) AS geometry FROM gtfs_stops INNER JOIN (SELECT unnest( '{1,2}'::int[] )) AS unnest ON gtfs_stops.id = unnest) AS shapes' # todo: filter
    end

    s = 'gtfs_stops.id, ST_LineLocatePoint(shapes.geometry::geometry, ST_ClosestPoint(shapes.geometry::geometry, ST_SetSRID(gtfs_stops.geometry, 4326))) AS line_s'
    GTFSStop.where(id: origins).select(s).joins(shape_join).where('shapes.id': shape_id).each do |row|
      shape_stop_distance[[row.id, shape_id]] = row.line_s
    end

    # First pass: line interpolation
    gaps.each do |gap|
      # open and close times
      o, c = gap
      o_st, c_st = stop_times[o], stop_times[c]
      o_time, c_time = o_st.origin_departure_time, c_st.origin_arrival_time
      # open and close distances - skip if we don't have a geometry
      o_distance, c_distance = shape_stop_distance[[o_st.origin_id, shape_id]], shape_stop_distance[[c_st.origin_id, shape_id]]
      # next unless o_distance && c_distance
      # interpolate on distance
      puts "d: #{o_distance} .. t: #{o_time}"
      p_distance = o_distance
      stop_times[o+1..c-1].each do |st|
        i_distance = shape_stop_distance.fetch([st.origin_id, shape_id])
        i_distance = [i_distance, c_distance].min # cannot exceed bounds
        i_distance = [i_distance, p_distance].max # cannot backtrack
        # next if i_distance < o_distance # cannot backtrack
        # next if i_distance > c_distance # cannot exceed bounds
        p_distance = i_distance # update last position
        # fraction of distance traveled in this gap
        pct = (i_distance - o_distance) / (c_distance - o_distance)
        t = (c_time - o_time) * pct + o_time
        puts ".. d: #{i_distance} .. t: #{t} .. pct #{pct} "
        st.origin_arrival_time |= t
        st.origin_departure_time |= t
      end
      puts "d: #{c_distance} .. t: #{c_time}"
    end

    # Second pass: distance interpolation
    # gaps = interpolate_find_gaps(stop_times)
    # gaps.each do |gap|
    #   # open and close times
    #   o, c = gap
    #   o_st, c_st = stop_times[o], stop_times[c]
    #   o_time, c_time = o_st.origin_departure_time, c_st.origin_arrival_time      
    # end

  end
end
