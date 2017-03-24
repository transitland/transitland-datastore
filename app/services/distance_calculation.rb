module DistanceCalculation
  OUTLIER_THRESHOLD = 100 # meters
  FIRST_MATCH_THRESHOLD = 25 # meters
  DISTANCE_PRECISION = 1

  def self.find_nearest_point(locators, nearest_seg_index)
    locators[nearest_seg_index].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
  end

  def self.nearest_segment_index_forward(locators, s, e, point)
    # the method is 'forward' since it's going along the line's direction to find the closest match.

    closest_point_candidates = locators[s..e].map{ |loc| loc.interpolate_point(Stop::GEOFACTORY) }
    closest_point_and_dist = closest_point_candidates.map{ |closest_point|
      [closest_point, closest_point.distance(point)]
    }.detect { |closest_point_and_dist| closest_point_and_dist[1] < FIRST_MATCH_THRESHOLD }

    # Since the first match is within FIRST_MATCH_THRESHOLD, it might not be the best (closest)
    # within the search range s through e.
    # So here we're walking up the line until we can't find a closer match - the next local minimum.
    unless closest_point_and_dist.nil?
      dist = closest_point_and_dist[1]
      i = closest_point_candidates.index(closest_point_and_dist[0])
      next_seg_dist = -1
      while next_seg_dist < dist
        break if i == locators[s..e].size - 1
        i += 1
        next if locators[s..e][i].segment.single_point?
        next_seg_dist = locators[s..e][i].interpolate_point(Stop::GEOFACTORY).distance(point)
        dist = next_seg_dist
      end
      return s + i
    end
    # If no match is found within the threshold, just take closest match wthin the search range.
    a = locators[s..e].map(&:distance_from_segment)
    s + a.index(a.min)
  end

  def self.distance_along_line_to_nearest(cartesian_route, nearest_point, nearest_seg_index)
    if nearest_seg_index == 0
      points = [cartesian_route.coordinates[0], [nearest_point.x, nearest_point.y]]
    else
      points = cartesian_route.line_subset(0, nearest_seg_index-1).coordinates << [nearest_point.x, nearest_point.y]
    end
    RouteStopPattern.line_string(points).length
  end

  def self.distance_to_nearest_point(stop_point_spherical, nearest_point)
    stop_point_spherical[:geometry].distance(RGeo::Feature.cast(nearest_point, RouteStopPattern::GEOFACTORY))
  end

  def self.test_distance(distance)
    distance < OUTLIER_THRESHOLD
  end

  def self.outlier_stop(rsp, spherical_stop)
    cartesian_line = cartesian_cast(rsp[:geometry])
    closest_point = cartesian_line.closest_point(cartesian_cast(spherical_stop))
    spherical_closest = RGeo::Feature.cast(closest_point, RouteStopPattern::GEOFACTORY)
    spherical_stop.distance(spherical_closest) > OUTLIER_THRESHOLD
  end

  def self.cartesian_cast(geometry)
    cartesian_factory = RGeo::Cartesian::Factory.new(srid: 4326)
    RGeo::Feature.cast(geometry, cartesian_factory)
  end

  def self.fallback_distances(rsp, stops=nil)
    rsp.stop_distances = [0.0]
    total_distance = 0.0
    stops = rsp.stop_pattern.map {|onestop_id| Stop.find_by_onestop_id!(onestop_id) } if stops.nil?
    stops.each_cons(2) do |stop1, stop2|
      total_distance += stop1[:geometry].distance(stop2[:geometry])
      rsp.stop_distances << total_distance
    end
    rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
  end

  def self.gtfs_shape_dist_traveled(rsp, stop_times, tl_stops, shape_distances_traveled)
    # assumes stop times and shapes BOTH have shape_dist_traveled, and they're in the same units
    # assumes the line geometry is not generated, and shape_points equals the rsp geometry.
    # TODO consider using a more efficient search method?
    rsp.stop_distances = []
    stop_times.each_with_index do |st, i|
      stop_onestop_id = rsp.stop_pattern[i]
      # Find segment along shape points where stop shape_dist_traveled is between the two shape points' shape_dist_traveled
      seg_index = -1
      dist1, dist2 = shape_distances_traveled.each_cons(2).detect do |d1, d2|
        seg_index += 1
        st.shape_dist_traveled.to_f >= d1 && st.shape_dist_traveled.to_f <= d2
      end

      if dist1.nil? || dist2.nil?
        if st.shape_dist_traveled.to_f < shape_distances_traveled[0]
          rsp.stop_distances << 0.0
        elsif st.shape_dist_traveled.to_f > shape_distances_traveled[-1]
          rsp.stop_distances << rsp[:geometry].length
        else
          raise StandardError.new("Problem finding stop distance for Stop #{stop_onestop_id}, number #{i + 1} of RSP #{rsp.onestop_id} using shape_dist_traveled")
        end
      else
        cartesian_line = cartesian_cast(rsp[:geometry])
        stop = tl_stops[i]
        nearest_point_on_line = cartesian_line.closest_point_on_segment(cartesian_cast(stop[:geometry]), seg_index)
        rsp.stop_distances << distance_along_line_to_nearest(cartesian_line, nearest_point_on_line, seg_index)
      end
    end
    rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
  end

  def self.calculate_distances(rsp, stops=nil)
    if stops.nil?
      stop_hash = Hash[Stop.find_by_onestop_ids!(rsp.stop_pattern).map { |s| [s.onestop_id, s] }]
      stops = rsp.stop_pattern.map{|s| stop_hash.fetch(s) }
    end
    if stops.map(&:onestop_id).uniq.size == 1
      rsp.stop_distances = Array.new(stops.size).map{|i| 0.0}
      return rsp.stop_distances
    end
    rsp.stop_distances = []
    route = cartesian_cast(rsp[:geometry])
    num_segments = route.coordinates.size - 1
    a = 0
    b = 0
    c = num_segments - 1
    last_stop_after_geom = route.after?(stops[-1][:geometry]) || self.outlier_stop(rsp, stops[-1][:geometry])
    previous_stop_before_geom = false
    stops.each_index do |i|
      stop_spherical = stops[i]
      this_stop = cartesian_cast(stop_spherical[:geometry])
      if i == 0 && (route.before?(stops[i][:geometry]) || self.outlier_stop(rsp, this_stop))
        previous_stop_before_geom = true
        rsp.stop_distances << 0.0
      elsif i == stops.size - 1 && last_stop_after_geom
        rsp.stop_distances << rsp[:geometry].length
      else
        if (i + 1 < stops.size - 1)
          next_stop_spherical = stops[i+1]
          next_stop = cartesian_cast(next_stop_spherical[:geometry])
          next_stop_locators = route.locators(next_stop)
          next_candidates = next_stop_locators[a..num_segments-1].map(&:distance_from_segment)
          c = a + next_candidates.index(next_candidates.min)
        else
          c = num_segments - 1
        end

        locators = route.locators(this_stop)
        b = nearest_segment_index_forward(locators, a, c, this_stop)
        nearest_point = find_nearest_point(locators, b)

        # The next stop's match may be too early and restrictive, so allow more segment possibilities
        if distance_to_nearest_point(stop_spherical, nearest_point) > FIRST_MATCH_THRESHOLD
          if (i + 2 < stops.size - 1)
            next_stop_spherical = stops[i+2]
            next_stop = cartesian_cast(next_stop_spherical[:geometry])
            next_stop_locators = route.locators(next_stop)
            next_candidates = next_stop_locators[a..num_segments-1].map(&:distance_from_segment)
            c = a + next_candidates.index(next_candidates.min)
          else
            c = num_segments - 1
          end
          b = nearest_segment_index_forward(locators, a, c, this_stop)
          nearest_point = find_nearest_point(locators, b)
        end

        distance = distance_along_line_to_nearest(route, nearest_point, b)
        if (i!=0)
          if (route.before?(stops[i][:geometry]) || self.outlier_stop(rsp, this_stop)) && previous_stop_before_geom
            previous_stop_before_geom = true
          else
            equivalent_stop = stops[i].onestop_id.eql?(stops[i-1].onestop_id) || stops[i][:geometry].eql?(stops[i-1][:geometry])
            if !equivalent_stop && !previous_stop_before_geom
              # this can happen if this stop matches to the same segment as the previous
              while (distance <= rsp.stop_distances[i-1])
                if (a == num_segments - 1)
                  distance = rsp[:geometry].length
                  break
                elsif (a == c)
                  # we should leave the faulty distance here (unless the interpolation tries to correct it)
                  # because something might be wrong with the RouteStopPattern.
                  break
                end
                a += 1
                b = nearest_segment_index_forward(locators, a, c, this_stop)
                nearest_point = find_nearest_point(locators, b)
                distance = distance_along_line_to_nearest(route, nearest_point, b)
              end
            end
            previous_stop_before_geom = false
          end
        end

        distance_to_line = distance_to_nearest_point(stop_spherical, nearest_point)
        if !test_distance(distance_to_line)
          if (i==0)
            rsp.stop_distances << 0.0
          elsif (i==stops.size-1)
            rsp.stop_distances << rsp[:geometry].length
          else
            # interpolate using half the distance between previous and next stop
            rsp.stop_distances << rsp.stop_distances[i-1] + stops[i-1][:geometry].distance(stops[i+1][:geometry])/2.0
          end
        else
          rsp.stop_distances << distance
        end
        a = b
      end
    end # end stop pattern loop
    rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
  end
end
