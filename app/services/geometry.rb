module Geometry
  module Lib
    def cartesian_cast(geometry)
      cartesian_factory = RGeo::Cartesian::Factory.new(srid: 4326)
      RGeo::Feature.cast(geometry, cartesian_factory)
    end

    def self.set_precision(points, precision)
      points.map { |c| c.map { |n| n.round(precision) } }
    end
  end

  class LineString
    extend Lib

    def self.line_string(points)
      RouteStopPattern::GEOFACTORY.line_string(
        points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
      )
    end

    def self.distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, nearest_seg_index)
      if nearest_seg_index == 0
        points = [route_line_as_cartesian.coordinates[0], [nearest_point.x, nearest_point.y]]
      else
        points = route_line_as_cartesian.line_subset(0, nearest_seg_index-1).coordinates << [nearest_point.x, nearest_point.y]
      end
      Geometry::LineString.line_string(points).length
    end
  end

  class OutlierStop
    extend Lib

    OUTLIER_THRESHOLD = 100 # meters

    def self.outlier_stop(stop, rsp)
      stop_as_spherical = stop[:geometry]
      stop_as_cartesian = self.cartesian_cast(stop_as_spherical)
      line_geometry_as_cartesian = self.cartesian_cast(rsp[:geometry])
      self.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      # trying to avoid casting when possible
      self.stop_distance_from_line(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian) > OUTLIER_THRESHOLD
    end

    def self.stop_distance_from_line(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      closest_point_as_cartesian = line_geometry_as_cartesian.closest_point(stop_as_cartesian)
      closest_point_as_spherical = RGeo::Feature.cast(closest_point_as_cartesian, RouteStopPattern::GEOFACTORY)
      stop_as_spherical.distance(closest_point_as_spherical)
    end

    def self.test_distance(distance)
      distance < OUTLIER_THRESHOLD
    end
  end

  class DistanceCalculation
    extend Lib

    DISTANCE_PRECISION = 1

    attr_accessor :stop_segment_matching_candidates, :cost_matrix

    def self.stop_before_geometry(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      line_geometry_as_cartesian.before?(stop_as_cartesian) || OutlierStop.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.stop_after_geometry(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      line_geometry_as_cartesian.after?(stop_as_cartesian) || OutlierStop.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.cost_matrix(stops, route_line_as_cartesian)
      # where 'cost' is stops' distances to line segments
      @cost_matrix = stops.map do |stop|
        stop_as_cartesian = self.cartesian_cast(stop[:geometry])
        locators = route_line_as_cartesian.locators(stop_as_cartesian)
        locators.map{|locator| [locator, locator.distance_from_segment]}
      end
    end

    def self.compute_matching_candidate_threshold(stops)
      # 1/2 of the average distance between two consecutive stops
      distances = stops.each_cons(2).map{|stop1,stop2| stop1[:geometry].distance(stop2[:geometry]) }
      distances.sum/(2.0*distances.size)
    end

    def self.best_possible_matching_segments_for_stops(route_line_as_cartesian, stops, skip_stops=[])
      @stop_segment_matching_candidates = []
      threshold = compute_matching_candidate_threshold(stops)
      min_index = 0
      stops.each_with_index.map do |stop, i|
        if skip_stops.include?(i)
          @stop_segment_matching_candidates[i] = nil
          next
        end
        matches = @cost_matrix[i].each_with_index.select do |locator_and_cost,j|
          distance = stop[:geometry].distance(locator_and_cost[0].interpolate_point(RouteStopPattern::GEOFACTORY))
          j >= min_index && distance <= threshold
        end
        if matches.to_a.empty?
          skip_stops << i
          next
        else
          max_index = matches.max_by{ |locator_and_cost,j| j }[1]
          min_index = matches.min_by{ |locator_and_cost,j| j }[1]
        end
        (i-1).downto(0).each do |j|
          next if @stop_segment_matching_candidates[j].nil?
          @stop_segment_matching_candidates[j] = @stop_segment_matching_candidates[j].select{|m| m[1] <= max_index }
        end
        @stop_segment_matching_candidates[i] = matches
      end
    end

    def self.matching_segments(stops, stop_index, route_line_as_cartesian, start_seg_index, skip_stops=[])
      if stop_index == stops.size
        return []
      end
      if skip_stops.include?(stop_index)
        forward_matches = self.matching_segments(stops, stop_index+1, route_line_as_cartesian, start_seg_index, skip_stops=skip_stops)
        if forward_matches.nil?
          return nil
        else
          return [nil].concat forward_matches
        end
      end

      @stop_segment_matching_candidates[stop_index].sort_by{|locator_and_cost,j| locator_and_cost[1] }.each do |locator_and_cost,index|
        next if index < start_seg_index
        forward_matches = self.matching_segments(stops, stop_index+1, route_line_as_cartesian, index, skip_stops=skip_stops)
        unless forward_matches.nil?
          forward_matches = [index].concat forward_matches
          validate = forward_matches.each_cons(2).each_with_index.all? do |m,j|
            m[0].nil? || m[1].nil? ||
            m[1] > m[0] ||
            m[1] == m[0] && @stop_segment_matching_candidates[stop_index+j].detect{|s| s[1] == m[0]}[0][0].distance_on_segment <= @stop_segment_matching_candidates[stop_index+j+1].detect{|s| s[1] == m[1]}[0][0].distance_on_segment
          end
          return forward_matches if validate
        end
      end
      return nil
    end

    def self.assign_first_stop_distance(rsp, route_line_as_cartesian, first_stop_as_spherical, first_stop_as_cartesian)
      # compare the second stop's closest segment point to the first. If the first stop's point
      # is after the second, then it has to be set to 0.0 because the line geometry
      # is likely to be too short by not coming up to the first stop.
      if self.stop_before_geometry(first_stop_as_spherical, first_stop_as_cartesian, route_line_as_cartesian)
        first_stop_locator_and_index = @cost_matrix[0].each_with_index.min_by{|locator_and_cost, i| locator_and_cost[1]}
        second_stop_locator_and_index = @cost_matrix[1].each_with_index.min_by{|locator_and_cost, i| locator_and_cost[1]}
        if first_stop_locator_and_index[1] < second_stop_locator_and_index[1]
          rsp.stop_distances[0] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,first_stop_locator_and_index[0][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),first_stop_locator_and_index[1])
        elsif first_stop_locator_and_index[1] == second_stop_locator_and_index[1] && first_stop_locator_and_index[0][0].distance_on_segment < second_stop_locator_and_index[0][0].distance_on_segment
          rsp.stop_distances[0] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,first_stop_locator_and_index[0][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),first_stop_locator_and_index[1])
        else
          rsp.stop_distances[0] = 0.0
        end
        return true
      end
      return false
    end

    def self.assign_last_stop_distance(rsp, route_line_as_cartesian, last_stop_as_spherical, last_stop_as_cartesian)
      # compare the last stop's closest segment point to the penultimate. If the last stop's point
      # is before the second, then it has to be set to the length of the line geometry, as it
      # is likely to be too short by not coming up to the last stop.
      if self.stop_after_geometry(last_stop_as_spherical, last_stop_as_cartesian, route_line_as_cartesian)
        last_stop_locator_and_index = @cost_matrix[-1].each_with_index.min_by{|locator_and_cost, i| locator_and_cost[1]}
        penultimate_stop_locator_and_index = @cost_matrix[-2].each_with_index.min_by{|locator_and_cost, i| locator_and_cost[1]}
        if last_stop_locator_and_index[1] > penultimate_stop_locator_and_index[1]
          rsp.stop_distances[-1] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,last_stop_locator_and_index[0][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),last_stop_locator_and_index[1])
        elsif last_stop_locator_and_index[1] == penultimate_stop_locator_and_index[1] && last_stop_locator_and_index[0][0].distance_on_segment > penultimate_stop_locator_and_index[0][0].distance_on_segment
          rsp.stop_distances[-1] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,last_stop_locator_and_index[0][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),last_stop_locator_and_index[1])
        else
          rsp.stop_distances[-1] = rsp[:geometry].length
        end
        return true
      end
      return false
    end

    def self.calculate_distances(rsp, stops=nil)
      # This algorithm borrows heavily, with modifications and adaptions, from OpenTripPlanner's approach seen at:
      # https://github.com/opentripplanner/OpenTripPlanner/blob/31e712d42668c251181ec50ad951be9909c3b3a7/src/main/java/org/opentripplanner/routing/edgetype/factory/GTFSPatternHopFactory.java#L610
      # First we compute reasonable segment matching possibilities for each stop based on a threshold.
      # Then, through a recursive call on each stop, we test the stop's segment possibilities in sorted order (of distance from the line)
      # until we find a list of all stop distances along the line that are in increasing order.

      # It may be worthwhile to consider the problem defined and solved algorithmically in:
      # http://www.sciencedirect.com/science/article/pii/0012365X9500325Q
      # Computing the stop distances along a line can be considered a variation of the Assignment problem.

      if stops.nil?
        stop_hash = Hash[Stop.find_by_onestop_ids!(rsp.stop_pattern).map { |s| [s.onestop_id, s] }]
        stops = rsp.stop_pattern.map{|s| stop_hash.fetch(s) }
      end
      if stops.map(&:onestop_id).uniq.size == 1
        rsp.stop_distances = Array.new(stops.size).map{|i| 0.0}
        return rsp.stop_distances
      end
      rsp.stop_distances = Array.new(stops.size)
      route_line_as_cartesian = self.cartesian_cast(rsp[:geometry])
      self.cost_matrix(stops, route_line_as_cartesian)

      skip_stops = []
      skip_first_stop = self.assign_first_stop_distance(rsp, route_line_as_cartesian, stops[0][:geometry], self.cartesian_cast(stops[0][:geometry]))
      skip_last_stop = self.assign_last_stop_distance(rsp, route_line_as_cartesian, stops[-1][:geometry], self.cartesian_cast(stops[-1][:geometry]))
      skip_stops << 0 if skip_first_stop
      skip_stops << stops.size - 1 if skip_last_stop

      self.best_possible_matching_segments_for_stops(route_line_as_cartesian, stops, skip_stops=skip_stops)
      best_segment_matches_for_stops = self.matching_segments(stops, 0, route_line_as_cartesian, 0, skip_stops=skip_stops)

      if best_segment_matches_for_stops.nil?
        # something is wrong, so we'll fake distances by using the closet match. Hopefully it'll throw quality issues
        # TODO: quality check for mismatched rsp shapes before all this, and set to nil?
        rsp.stop_distances = @cost_matrix.map do |m|
          locator_and_cost, i = m.each_with_index.min_by{|locator_and_cost,i| locator_and_cost[1] }
          closest_point = locator_and_cost[0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
          LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,closest_point,i)
        end
        return rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
      end
      stops.each_with_index do |stop, i|
        next if skip_stops.include?(i)
        current_stop_as_spherical = stop[:geometry]
        current_stop_as_cartesian = self.cartesian_cast(current_stop_as_spherical)
        locator = @cost_matrix[i][best_segment_matches_for_stops[i]][0]
        rsp.stop_distances[i] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,locator.interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),best_segment_matches_for_stops[i])
      end
      # now, handle outlier stops that are not the first or last stops
      skip_stops.reject{|i| [0, stops.size-1].include?(i) }.each do |i|
        # interpolate between the previous and next stop distances
        rsp.stop_distances[i] = (rsp.stop_distances[i-1] + rsp.stop_distances[i+1])/2.0
      end
      rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
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

    def self.validate_shape_dist_traveled(stop_times, shape_distances_traveled)
      if (stop_times.all?{ |st| st.shape_dist_traveled.present? } && shape_distances_traveled.all?(&:present?))
        # checking for any out-of-order distance values,
        # or whether any stop except the last has distance > the last shape point distance.
        return stop_times.each_cons(2).none? { |st1,st2|
          (st1.shape_dist_traveled.to_f >= st2.shape_dist_traveled.to_f && !st1.stop_id.eql?(st2.stop_id)) ||
          st1.shape_dist_traveled.to_f > shape_distances_traveled[-1].to_f
        }
      else
        return false
      end
    end

    def self.gtfs_shape_dist_traveled(rsp, stop_times, tl_stops, shape_distances_traveled)
      # assumes stop times and shapes BOTH have shape_dist_traveled, and they're in the same units
      # assumes the line geometry is not generated, and shape_points equals the rsp geometry.
      rsp.stop_distances = []
      search_and_seg_index = 0
      stop_times.each_with_index do |st, i|
        stop_onestop_id = rsp.stop_pattern[i]

        if st.shape_dist_traveled.to_f < shape_distances_traveled[0]
          rsp.stop_distances << 0.0
        elsif st.shape_dist_traveled.to_f > shape_distances_traveled[-1]
          rsp.stop_distances << rsp[:geometry].length
        else
          # Find segment along shape points where stop shape_dist_traveled is between the two shape points' shape_dist_traveled
          # need to account for stops matching to same segment
          j = -1
          dist1, dist2 = shape_distances_traveled[search_and_seg_index..-1].each_cons(2).detect do |d1, d2|
            j += 1
            st.shape_dist_traveled.to_f >= d1 && st.shape_dist_traveled.to_f <= d2
          end

          search_and_seg_index = search_and_seg_index + j

          if dist1.nil? || dist2.nil?
            raise StandardError.new("Problem finding stop distance for Stop #{stop_onestop_id}, number #{i + 1} of RSP #{rsp.onestop_id} using shape_dist_traveled")
          else
            route_line_as_cartesian = self.cartesian_cast(rsp[:geometry])
            stop = tl_stops[i]
            locators = route_line_as_cartesian.locators(self.cartesian_cast(stop[:geometry]))
            seg_length = shape_distances_traveled[search_and_seg_index+1] - shape_distances_traveled[search_and_seg_index]
            seg_dist_ratio = seg_length > 0 ? (st.shape_dist_traveled.to_f - shape_distances_traveled[search_and_seg_index]) / seg_length : 0
            point_on_line = locators[search_and_seg_index].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326), seg_dist=seg_dist_ratio)
            rsp.stop_distances << LineString.distance_along_line_to_nearest_point(route_line_as_cartesian, point_on_line, search_and_seg_index)
          end
        end
      end
      rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
    end
  end
end
