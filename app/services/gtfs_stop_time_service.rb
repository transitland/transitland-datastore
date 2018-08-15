class GTFSStopTimeService

  def self.clean_stop_times(stop_times)
    # Sort by stop_sequence
    stop_times.sort_by! { |st| st.stop_sequence }
    # If we only have 1 time, assume it is both arrival and departure
    times = []
    distances = []
    stop_times.each do |st|
      (st.arrival_time = st.departure_time) if st.arrival_time.nil?
      (st.departure_time = st.arrival_time) if st.departure_time.nil?
      times << st.arrival_time if st.arrival_time
      times << st.departure_time if st.departure_time
      distances << st.shape_dist_traveled if st.shape_dist_traveled
    end
    # These two values are required by spec
    return [] if stop_times.first.departure_time.nil?
    return [] if stop_times.last.arrival_time.nil?
    # Ensure shape_dist_traveled is increasing
    return [] unless distances == distances.sort
    # Ensure time is increasing
    return [] unless times == times.sort
    # OK
    return stop_times
  end

  def self.interpolate_stop_times(stop_times, shape_id, d1=nil, d2=nil)
    # Tidy up our stop_times
    stop_times = clean_stop_times(stop_times)

    # Measure shape length and stop distances (and cache)
    d1 ||= {}
    measure_stops = stop_times.map(&:stop_id).select { |i| d1[i].nil? }
    d1 = get_shape_stop_distances(measure_stops, shape_id, distances=d1)

    # Do we have values for shape_dist_traveled on stop_times AND shape?
    if stop_times.map(&:shape_dist_traveled).all?
      s1 = stop_times.map(&:shape_dist_traveled)
      s2 = GTFSShape.find(shape_id).geometry[:coordinates].map { |c| c[2] }
      s2d = s2.last - s2.first
      shape_length = d1[nil]
      if s2.all? && s2d > 0 && shape_length && shape_length > 0
        # Convert stop_times shape_dist_traveled to meters
        cm = shape_length / s2d
        stop_times.each { |st| stop_times.shape_dist_traveled *= cm }
      else 
        # Reset shape_dist_traveled
        stop_times.each { |st| stop_times.shape_dist_traveled = nil }
      end
    else
      # Reset shape_dist_traveled
      stop_times.each { |st| stop_times.shape_dist_traveled = nil }
    end

    # Do we need to fall back to linear stop-stop distances?
    distances = stop_times.map { |st| d1[st.stop_id] }
    distances.reverse! if distances.first > distances.last
    if distances != distances.sort
      d1 = get_linear_stop_distances(trip_pattern)
    end

    stop_times.each { |st| st.shape_dist_traveled = nil }
    stop_times.first.shape_dist_traveled = distances[stop_times.first.stop_id]
    stop_times.last.shape_dist_traveled = distances[stop_times.last.stop_id]

    # Fill in dist gaps. First pass: distance; second pass: linear
    interpolate_find_dist(stop_times).each { |o,c| interpolate_distance(stop_times[o..c], d1) }
    # Fill in times
    interpolate_find_time(stop_times).each { |o,c| interpolate_time(stop_times[o..c]) }
    return stop_times
  end

  def self.interpolate_time(stop_times)
    o_distance = stop_times.first.shape_dist_traveled
    c_distance = stop_times.last.shape_dist_traveled
    o_time = stop_times.first.departure_time
    c_time = stop_times.last.arrival_time
    stop_times.each do |st|
      next if st.arrival_time && st.departure_time
      pct = (st.shape_dist_traveled - o_distance) / (c_distance - o_distance)
      st.arrival_time = st.departure_time = (pct * (c_time - o_time)) + o_time
      st.interpolated += 10
    end
  end

  def self.interpolate_distance(stop_times, distances)
    # check that we can interpolate reasonably
    d = stop_times.map { |st| st.shape_dist_travelled || distances[st.stop_id] }
    return unless d == d.sort && d.all?
    stop_times.zip(d).each do |st,i|
      next if st.shape_dist_traveled
      st.shape_dist_traveled = i
      st.interpolated = 1
    end
  end

  def self.interpolate_linear(stop_times)
    o, c = stop_times.first.shape_dist_traveled, stop_times.last.shape_dist_traveled
    increment = (c - o) / (stop_times.size.to_f-1)
    stop_times.each_with_index do |st,i| 
      next if st.shape_dist_traveled
      st.shape_dist_traveled = increment * i + o
      st.interpolated = 2
    end
  end

  def self.interpolate_find_time(stop_times)
    gaps = []
    o, c = nil, nil
    stop_times.each_with_index do |st, i|
      # close an open gap
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

  def self.interpolate_find_dist(stop_times)
    gaps = []
    o, c = nil, nil
    stop_times.each_with_index do |st, i|
      if o && st.shape_dist_traveled
        gaps << [o, i] if (i-o > 1)
        o = nil
      end
      if o.nil? && st.shape_dist_traveled
        o = i
      end
    end
    return gaps
  end  

  def self.get_shape_stop_segments(trip_pattern, shape_id, cache=nil, maxdistance=200, segments=1)
    # Split line into segments, 
    #   get distance from each stop to each segment and the point on the segment.
    cache ||= {}
    trip_pattern = trip_pattern.select { |i| !cache.key?(i) }
    return cache unless trip_pattern.size > 0
    shape_id = shape_id.to_i
    trip_pattern = trip_pattern.map(&:to_i)
    maxdistance = maxdistance.to_i
    segments = segments.to_i
    # linesubs: break shape into segments, as geography
    # segs: get cumulative line distance, including the current segment
    # gtfs_stops: get stops
    # gtfs_stops_segs: find distance between each stop and each segment
    # filter by stop distance from line < maxdistance
    s = <<-EOF
      WITH
      linesubs AS ( 
          SELECT 
              i AS seg_id,
              ST_LineSubstring(gtfs_shapes.geometry::geometry, i/#{segments}::float,(i+1)/#{segments}::float)::geography AS shape
          FROM gtfs_shapes, GENERATE_SERIES(0,#{segments-1}) AS i
          WHERE id = #{shape_id}
      ),
      segs AS ( 
          SELECT 
              seg_id,
              shape,
              ST_Length(shape) as seg_length,
              sum(ST_Length(shape)) OVER (ORDER BY seg_id) AS seg_length_sum
          FROM linesubs
      ),
      gtfs_stops_segs AS ( 
          SELECT
              gtfs_stops.id,
              seg_id,
              ST_ShortestLine(segs.shape::geometry, gtfs_stops.geometry::geometry) AS seg_shortest,
              ST_Length(ST_ShortestLine(segs.shape::geometry, gtfs_stops.geometry::geometry)::geography) AS seg_distance
          FROM gtfs_stops
          INNER JOIN segs ON true
          WHERE gtfs_stops.id IN (#{trip_pattern.join(',')})
      )
      SELECT
        id, 
        seg_id,
        seg_distance,
        ST_AsGeoJSON(seg_shortest) AS seg_shortest_geojson,
        ST_Length(
          ST_LineSubstring(
            segs.shape::geometry, 
            0.0, 
            ST_LineLocatePoint(
              segs.shape::geometry, 
              ST_PointN(seg_shortest, 1)
            )
          )::geography
        ) + segs.seg_length_sum - segs.seg_length AS seg_traveled
      FROM gtfs_stops_segs INNER JOIN segs USING(seg_id) 
      WHERE seg_distance < #{maxdistance}
    EOF
    s = s.squish
    trip_pattern.each { |i| cache[i] ||= [] }
    features = []
    GTFSStop.find_by_sql(s).each do |row|
      puts row.to_json
      cache[row['id']] << [row['seg_distance'], row['seg_traveled']]
      features << {type: 'Feature', properties: {"stroke" => "#ff0018", "stroke-width": 4}, geometry: JSON.parse(row['seg_shortest_geojson'])} 
    end
    GTFSStop.find(trip_pattern).each { |s| features << {type: 'Feature', properties: {}, geometry: s.geometry(as: :geojson) }}
    features << {type: 'Feature', properties: {"stroke-width": 4, "stroke" => "#0000ff"}, geometry: GTFSShape.find(shape_id).geometry(as: :geojson)}
    puts ({type: "FeatureCollection", features: features}).to_json
    return cache    
    # Get the closest segment, weighted by how far it advances shape_dist_traveled
    # shape_dist_traveled = 0.0
    # trip_pattern.each do |i|
    #   a = cache[i] || []
    #   scored = a.map do |seg_distance, seg_percent, seg_length, seg_length_sum|        
    #     dist = (seg_length * seg_percent + seg_length_sum) - shape_dist_traveled
    #     score = dist / seg_distance
    #     [score, dist]
    #   end
    #   s = scored.select { |_,seg_distance| seg_distance >= shape_dist_traveled }.sort.last
    #   if s
    #     puts "#{i} -> #{s[1]}"
    #   else
    #     puts "#{i} -> no result"
    #   end
    # end
    # return cache
  end

  def self.get_linear_stop_distances(trip_pattern, distances=nil)
    trip_pattern = trip_pattern.map(&:to_i)
    t1 = trip_pattern[0..-2]
    t2 = trip_pattern[1..-1]
    s = <<-EOF
      SELECT 
        o.id AS id,
        o.seg_id AS seg_id, 
        ST_Length(ST_MakeLine(o.geometry::geometry, d.geometry::geometry)::geography) AS seg_length
      FROM
        (SELECT stop_name,seg_id,id,geometry FROM gtfs_stops, unnest(array[#{t1.join(',')}]) WITH ORDINALITY AS t(unnest,seg_id) where id = unnest) o, 
        (SELECT stop_name,seg_id,id,geometry FROM gtfs_stops, unnest(array[#{t2.join(',')}]) WITH ORDINALITY AS t(unnest,seg_id) where id = unnest) d 
      WHERE o.seg_id = d.seg_id ORDER BY o.seg_id
    EOF
    cache = {}
    d = 0.0
    GTFSStop.find_by_sql(s.squish).each do |row|
      puts row.to_json
      d += row['seg_length']
      cache[row['id']] = [0.0, d]
    end
    puts trip_pattern.map { |i| cache[i] }
    return cache
  end
end
