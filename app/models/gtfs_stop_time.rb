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
#  arrival_time             :integer
#  departure_time           :integer
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

class GTFSStopTime < ActiveRecord::Base
  belongs_to :feed_version
  belongs_to :trip, class_name: 'GTFSTrip'
  belongs_to :stop, class_name: 'GTFSStop'
  belongs_to :destination, class_name: 'GTFSStop'
  belongs_to :trip, class_name: 'GTFSTrip'
  has_one :shape, :through => :trip

  def self.interpolate_stop_times(stop_times)
    stop_times = clean_stop_times(stop_times)

    # Return early if possible
    gaps = interpolate_find_gaps(stop_times)
    return stop_times if gaps.size == 0

    # Measure stops along line
    shape_id = GTFSTrip.find(stop_times.first.trip_id).shape_id
    trip_pattern = stop_times.map(&:stop_id)
    shape_stop_distance = {}
    shape_id = nil
    
    # Calculate line percent from closest point to stop
    s = 'gtfs_stops.id, ST_LineLocatePoint(shapes.geometry::geometry, ST_ClosestPoint(shapes.geometry::geometry, ST_SetSRID(gtfs_stops.geometry, 4326))) AS line_s'
    g = GTFSStop.select(s)
    
    # Create shape if necessary
    if shape_id
      g = g.joins('INNER JOIN gtfs_shapes AS shapes ON true')
    else
      shape_id = 0
      g = g.joins("INNER JOIN (SELECT 0 as id, ST_SetSRID(ST_MakeLine(geometry), 4326) AS geometry FROM (SELECT geometry FROM gtfs_stops INNER JOIN (SELECT unnest,ordinality FROM unnest( ARRAY[#{trip_pattern.join(',')}] ) WITH ORDINALITY) as unnest ON gtfs_stops.id = unnest ORDER BY ordinality) as q) AS shapes ON true")
    end

    # Filter
    g = g.where('shapes.id': shape_id, id: trip_pattern)

    g.each do |row|
      shape_stop_distance[shape_id] = {} if shape_stop_distance[shape_id].nil?
      shape_stop_distance[shape_id][row.id] = row.line_s
    end

    # First pass: line interpolation
    # gaps.each do |gap|
    #   o, c = gap
    #   interpolate_gap_distance(stop_times[o..c], shape_stop_distance[shape_id])
    # end

    # Second pass: distance interpolation
    gaps = interpolate_find_gaps(stop_times)
    gaps.each do |gap|
      o, c = gap
      interpolate_gap_linear(stop_times[o..c])
    end
    return stop_times
  end

  private

  def self.clean_stop_times(stop_times)
    # Sort by stop_sequence
    stop_times.sort_by! { |st| st.stop_sequence }

    # If we only have 1 time, assume it is both arrival and departure
    stop_times.each do |st|
      (st.arrival_time = st.departure_time) if st.arrival_time.nil?
      (st.departure_time = st.arrival_time) if st.departure_time.nil?
    end

    # Ensure time is positive
    current = stop_times.first.arrival_time
    stop_times.each do |st|
      s = st.arrival_time
      fail Exception.new('cannot go backwards in time') if s && s < current
      current = s if s
      s = st.departure_time
      fail Exception.new('cannot go backwards in time') if s && s < current
      current = s if s
    end

    # These two values are required by spec
    fail Exception.new('missing first departure time') if stop_times.first.departure_time.nil?
    fail Exception.new('missing last arrival time') if stop_times.last.arrival_time.nil?
    return stop_times
  end

  def self.interpolate_find_gaps(stop_times)
    gaps = []
    o, c = nil, nil
    stop_times.each_with_index do |st, i|
      # close an open gap
      # puts "i: #{i} st: #{st.stop_sequence} stop: #{st.stop_id} arrival_time: #{st.arrival_time} departure_time: #{st.departure_time}"
      if o && st.arrival_time
        gaps << [o, i] if (i-o > 1)
        o = nil
      end
      # open a new gap
      if o.nil? && st.departure_time
        o = i
      end
    end
    return gaps
  end

  def self.interpolate_gap_distance(stop_times, distances)
    # open and close times
    o_time = stop_times.first.departure_time
    c_time = stop_times.last.arrival_time
    # open and close distances
    o_distance = distances[stop_times.first.stop_id]
    c_distance = distances[stop_times.last.stop_id]
    # check that we can interpolate reasonably
    p_distance = o_distance
    stop_times.each do |st|
      i_distance = distances[st.stop_id]
      return unless i_distance
      return if i_distance < p_distance # cannot backtrack
      return if i_distance > c_distance # cannot exceed end
      p_distance = i_distance
    end
    # interpolate on distance
    puts "\n"
    puts "length: #{c_distance - o_distance} duration: #{c_time - o_time}"
    puts "o_distance: #{o_distance} o_time: #{o_time}"
    stop_times[1...-1].each do |st|
      i_distance = distances[st.stop_id]
      pct = (i_distance - o_distance) / (c_distance - o_distance)
      i_time = (c_time - o_time) * pct + o_time
      puts "i_distance: #{i_distance} pct: #{pct} i_time: #{i_time}"
      st.arrival_time = i_time
      st.departure_time = i_time
    end
    puts "c_distance: #{c_distance} c_time: #{c_time}"
    puts "\n"
    return true
  end

  def self.interpolate_gap_linear(stop_times)
    # open and close times
    o_time = stop_times.first.departure_time
    c_time = stop_times.last.arrival_time
    # interpolate on time
    p_time = o_time
    puts "\n"
    puts "duration: #{c_time - o_time}"
    puts "i: 0 o_time: #{o_time}"
    stop_times[1...-1].each_with_index do |st,i|
      pct = pct = (i+1) / (stop_times.size.to_f-1)
      i_time = (c_time - o_time) * pct + o_time
      puts "i: #{i+1} pct: #{pct} i_time: #{i_time} "
      st.arrival_time = i_time
      st.departure_time = i_time
    end
    puts "i: #{stop_times.size-1} c_time: #{c_time}"
    puts "\n"
  end
end
