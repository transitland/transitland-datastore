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

    # NOTE: The determination for outliers during distance calculation
    # may be different than the one for quality checks.

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

    def self.compute_cost_matrix(stops, route_line_as_cartesian)
      # where 'cost' is stops' distances to line segments
      cost_matrix = stops.map do |stop|
        stop_as_cartesian = self.cartesian_cast(stop[:geometry])
        locators = route_line_as_cartesian.locators(stop_as_cartesian)
        locators.map{|locator| [locator, locator.distance_from_segment]}
      end
    end

    def compute_matching_candidate_thresholds(stops)
      # average minimum distance from stop to line
      mins = @cost_matrix.each_with_index.map{|locators_and_costs,i| stops[i][:geometry].distance(locators_and_costs.min_by{|lc| lc[1]}[0].interpolate_point(Stop::GEOFACTORY)) }
      y = mins.sum/mins.size.to_f

      thresholds = []

      stops.each_with_index do |stop, i|
        if i == 0
          x = (stops[0][:geometry].distance(stops[1][:geometry]))/2.0
        elsif i == stops.size - 1
          x = (stops[-1][:geometry].distance(stops[-2][:geometry]))/2.0
        else
          x = (stops[i-1][:geometry].distance(stops[i][:geometry]) + stops[i][:geometry].distance(stops[i+1][:geometry]))/4.0
        end
        thresholds << Math.sqrt(x**2 + y**2)
      end
      thresholds
    end

    def best_possible_matching_segments_for_stops(route_line_as_cartesian, stops, skip_stops=[])
      # prune segment matches per stop that are impossible
      @stop_segment_matching_candidates = []
      thresholds = compute_matching_candidate_thresholds(stops)
      min_index = 0
      stops.each_with_index.map do |stop, i|
        if skip_stops.include?(i)
          @stop_segment_matching_candidates[i] = nil
          next
        end
        matches = @cost_matrix[i].each_with_index.select do |locator_and_cost,j|
          distance = stop[:geometry].distance(locator_and_cost[0].interpolate_point(RouteStopPattern::GEOFACTORY))
          j >= min_index && distance <= thresholds[i]
        end
        if matches.to_a.empty?
          # an outlier
          skip_stops << i
          next
        else
          max_index = matches.max_by{ |locator_and_cost,j| j }[1]
          min_index = matches.min_by{ |locator_and_cost,j| j }[1]
        end
        # prune segments of previous stops whose indexes are greater than the max of the current stop's segments.
        (i-1).downto(0).each do |j|
          next if @stop_segment_matching_candidates[j].nil?
          @stop_segment_matching_candidates[j] = @stop_segment_matching_candidates[j].select{|m| m[1] <= max_index }
        end
        @stop_segment_matching_candidates[i] = matches
      end
    end

    def assign_first_stop_distance(rsp, route_line_as_cartesian, first_stop_as_spherical, first_stop_as_cartesian)
      # compare the second stop's closest segment point to the first. If the first stop's point
      # is after the second, then it has to be set to 0.0 because the line geometry
      # is likely to be too short by not coming up to the first stop.
      if self.class.stop_before_geometry(first_stop_as_spherical, first_stop_as_cartesian, route_line_as_cartesian)
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

    def assign_last_stop_distance(rsp, route_line_as_cartesian, penultimate_match)
      # compare the last stop's closest segment point to the penultimate. If the last stop's point
      # is before the penultimate, then it has to be set to the length of the line geometry, as the line
      # is likely to be too short by not coming up to the last stop.
      last_stop_locator_and_index = @cost_matrix[-1].each_with_index.select{|locator_and_cost, i| i >= penultimate_match }.min_by{|locator_and_cost, i| locator_and_cost[1]}
      if last_stop_locator_and_index[1] > penultimate_match
        rsp.stop_distances[-1] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,last_stop_locator_and_index[0][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),last_stop_locator_and_index[1])
      elsif last_stop_locator_and_index[1] == penultimate_match && last_stop_locator_and_index[0][0].distance_on_segment > @cost_matrix[-2][penultimate_match][0].distance_on_segment
        rsp.stop_distances[-1] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,last_stop_locator_and_index[0][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),last_stop_locator_and_index[1])
      else
        rsp.stop_distances[-1] = rsp[:geometry].length
      end
    end

    def self.fallback_distances(rsp, stops=nil, cost_matrix=nil)
      # a naive assigment of stops to closest segment.
      # This can create inaccuracies, which may be intentional for quality checks to pick up.
      route_line_as_cartesian = self.cartesian_cast(rsp[:geometry])
      cost_matrix = self.compute_cost_matrix(stops, route_line_as_cartesian) if cost_matrix.nil?
      rsp.stop_distances = cost_matrix.map do |m|
        locator_and_cost, i = m.each_with_index.min_by{|locator_and_cost,i| locator_and_cost[1] }
        closest_point = locator_and_cost[0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
        LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,closest_point,i)
      end
      rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
    end

    def self.straight_line_distances(rsp, stops=nil)
      # stop distances on straight lines from stop to stop
      rsp.stop_distances = [0.0]
      total_distance = 0.0
      stops = rsp.stop_pattern.map {|onestop_id| Stop.find_by_onestop_id!(onestop_id) } if stops.nil?
      stops.each_cons(2) do |stop1, stop2|
        total_distance += stop1[:geometry].distance(stop2[:geometry])
        rsp.stop_distances << total_distance
      end
      rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
    end
  end

  class EnhancedOTPDistances < DistanceCalculation

    attr_accessor :matching_method_calls, :matching_method_call_limit

    def compute_matching_method_call_limit(num_stops)
      # prevent runaway loops from bad data or any lurking bugs
      k = 1.0 + 3.0*(Math.log(num_stops)/num_stops**1.2) # max 'average' allowable num of segment candidates per stop. Approaches 1.0 as num_stops increases
      @matching_method_call_limit = 3.0*num_stops*k**num_stops
    end

    # def matching_segments(stops, stop_index, start_seg_index, skip_stops=[])
    #   return nil if @matching_method_calls > @matching_method_call_limit || @matching_method_calls > Geometry::DistanceCalculation::MAX_NUM_STOPS_FOR_RECURSION
    #   @matching_method_calls += 1
    #   if stop_index == stops.size
    #     return []
    #   end
    #   if skip_stops.include?(stop_index)
    #     forward_matches = self.matching_segments(stops, stop_index+1, start_seg_index, skip_stops=skip_stops)
    #     if forward_matches.nil?
    #       return nil
    #     else
    #       return [nil].concat forward_matches
    #     end
    #   end
    #
    #   @stop_segment_matching_candidates[stop_index].sort_by{|locator_and_cost,index| locator_and_cost[1] }.each do |locator_and_cost,index|
    #     next if index < start_seg_index
    #     # sometimes the current stop's segment candidates are the same as the previous, and the distance on the segment is out of order.
    #     # in this case, we need to continue the loop for the current stop, not the previous.
    #     previous_match_candidates = @stop_segment_matching_candidates[stop_index-1]
    #     next if stop_index != 0 && index == start_seg_index && !previous_match_candidates.nil? && (locator_and_cost[0].distance_on_segment < previous_match_candidates.detect{|lc,i| start_seg_index == i}[0][0].distance_on_segment)
    #     forward_matches = self.matching_segments(stops, stop_index+1, index, skip_stops=skip_stops)
    #     unless forward_matches.nil?
    #       forward_matches = [index].concat forward_matches
    #       valid = forward_matches.each_cons(2).each_with_index.all? do |m,j|
    #         # Preserve segment order, unless stops match to same segment. If so,
    #         # check that their positions along the segment are preserved.
    #         equivalent_stops = stops[stop_index+j].onestop_id.eql?(stops[stop_index+j+1]) || stops[stop_index+j][:geometry].eql?(stops[stop_index+j+1][:geometry])
    #         m[0].nil? || m[1].nil? ||
    #         m[1] > m[0] ||
    #         m[1] == m[0] && (@stop_segment_matching_candidates[stop_index+j].detect{|s| s[1] == m[0]}[0][0].distance_on_segment <= @stop_segment_matching_candidates[stop_index+j+1].detect{|s| s[1] == m[1]}[0][0].distance_on_segment || equivalent_stops)
    #       end
    #       return forward_matches if valid
    #     end
    #   end
    #   return nil
    # end

    def forward_matching_segments(stops, stop_index, start_seg_index, stack, tried_index_for_stop: nil, skip_stops: [])
      stops[stop_index..-1].each_with_index do |stop, i|
        if skip_stops.include?(stop_index + i)
          stack.push [stop_index + i, nil]
        else
          reject_seg_index = Proc.new{|locator_and_cost, index|
              current_match_candidates = @stop_segment_matching_candidates[stop_index+i]
              index < start_seg_index || (index == start_seg_index && !current_match_candidates.nil? && (locator_and_cost[0].distance_on_segment < current_match_candidates.detect{|lc,j| start_seg_index == j}[0][0].distance_on_segment))
          }
          start_search = i==0 && !tried_index_for_stop.nil? ? tried_index_for_stop + 1 : 0
          index = @stop_segment_matching_candidates[i+stop_index][start_search..-1].reject{|locator_and_cost,index| reject_seg_index.call(locator_and_cost, index) }.min_by{|locator_and_cost,index| locator_and_cost[1] }
          unless index.nil?
            stack.push [stop_index + i, index[1]] unless index.nil?
            start_seg_index = index[1]
          end
        end
      end
    end

    def matching_segments(stops, stop_index, start_seg_index, skip_stops=[])

      stack = []
      segment_matches = Array.new(stops.size)

      forward_matching_segments(stops, 0, 0, stack, skip_stops: skip_stops)

      while stack.any?
        stop_index, stop_seg_match = stack.pop
        next if @matching_method_calls > @matching_method_call_limit
        @matching_method_calls += 1
        next if skip_stops.include?(stop_index)

        if stop_index == stops.size - 1
          segment_matches[stop_index] = stop_seg_match
        else
          valid = ([stop_seg_match].concat segment_matches[stop_index+1..-1]).each_cons(2).each_with_index.all? do |m,j|
            # Preserve segment order, unless stops match to same segment. If so,
            # check that their positions along the segment are preserved.
            equivalent_stops = stops[stop_index+j].onestop_id.eql?(stops[stop_index+j+1]) || stops[stop_index+j][:geometry].eql?(stops[stop_index+j+1][:geometry])
            m[0].nil? || m[1].nil? ||
            m[1] > m[0] ||
            m[1] == m[0] && (@stop_segment_matching_candidates[stop_index+j].detect{|s| s[1] == m[0]}[0][0].distance_on_segment <= @stop_segment_matching_candidates[stop_index+j+1].detect{|s| s[1] == m[1]}[0][0].distance_on_segment || equivalent_stops)
          end
          if stop_seg_match && (!valid || (segment_matches[stop_index+1].nil? && !skip_stops.include?(stop_index + 1)))
            index_of_seg_tried = @stop_segment_matching_candidates[stop_index].map{|locator_and_cost,seg_index| seg_index}.index(stop_seg_match)
            forward_matching_segments(stops, stop_index, stop_seg_match, stack, tried_index_for_stop: index_of_seg_tried, skip_stops: skip_stops)
          else
            segment_matches[stop_index] = stop_seg_match
          end
        end
      end

      return segment_matches
    end

    def matches_invalid?(best_single_segment_match_for_stops, skip_stops)
      best_single_segment_match_for_stops.nil? ||
      best_single_segment_match_for_stops.each_with_index.any?{|b,i| b.nil? && !skip_stops.include?(i)} ||
      best_single_segment_match_for_stops.each_cons(2).any?{|m1,m2| m1.nil? && m2.nil?}
    end

    def calculate_distances(rsp, stops=nil)
      # This algorithm borrows heavily, with modifications and adaptions, from OpenTripPlanner's approach seen at:
      # https://github.com/opentripplanner/OpenTripPlanner/blob/31e712d42668c251181ec50ad951be9909c3b3a7/src/main/java/org/opentripplanner/routing/edgetype/factory/GTFSPatternHopFactory.java#L610
      # First we compute reasonable segment matching possibilities for each stop based on a threshold.
      # Then, through a recursive call on each stop, we test the stop's segment possibilities in sorted order (of distance from the line)
      # until we find a list of all stop distances along the line that are in increasing order.
      # Ultimately, it's still a greedy heuristic algorithm, so inaccuracy is not guaranteed.

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
      route_line_as_cartesian = self.class.cartesian_cast(rsp[:geometry])
      @cost_matrix = self.class.compute_cost_matrix(stops, route_line_as_cartesian)

      skip_stops = []
      skip_first_stop = assign_first_stop_distance(rsp, route_line_as_cartesian, stops[0][:geometry], self.class.cartesian_cast(stops[0][:geometry]))
      skip_stops << 0 if skip_first_stop
      skip_last_stop = self.class.stop_after_geometry(stops[-1][:geometry], self.class.cartesian_cast(stops[-1][:geometry]), route_line_as_cartesian)
      skip_stops << stops.size - 1 if skip_last_stop

      best_possible_matching_segments_for_stops(route_line_as_cartesian, stops, skip_stops=skip_stops)
      @matching_method_calls = 0
      compute_matching_method_call_limit(stops.size)
      best_single_segment_match_for_stops = matching_segments(stops, 0, 0, skip_stops=skip_stops)

      if matches_invalid?(best_single_segment_match_for_stops, skip_stops)
        # something is wrong, so we'll fake distances by using the closest match. It should throw distance quality issues later on.
        # TODO: quality check for mismatched rsp shapes before all this, and set to nil?
        return self.class.fallback_distances(rsp, stops=stops, cost_matrix=@cost_matrix)
      end
      stops.each_with_index do |stop, i|
        next if skip_stops.include?(i)
        current_stop_as_spherical = stop[:geometry]
        current_stop_as_cartesian = self.class.cartesian_cast(current_stop_as_spherical)
        locator = @cost_matrix[i][best_single_segment_match_for_stops[i]][0]
        rsp.stop_distances[i] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,locator.interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),best_single_segment_match_for_stops[i])
      end
      # now, handle outlier stops that are not the first or last stops
      skip_stops.reject{|i| [0, stops.size-1].include?(i) }.each do |i|
        # interpolate between the previous and next stop distances
        rsp.stop_distances[i] = (rsp.stop_distances[i-1] + rsp.stop_distances[i+1])/2.0
      end
      if skip_last_stop || skip_stops.include?(stops.size - 1)
        assign_last_stop_distance(rsp, route_line_as_cartesian, best_single_segment_match_for_stops[-2])
      end
      rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
    end
  end

  class ABCDistances < DistanceCalculation
    def index_of_line_segment_with_nearest_point(stop_index, start, stop)
      distances_from_segs = @cost_matrix[stop_index][start..stop].map{|locator_and_dist| locator_and_dist[1] }
      index = start + distances_from_segs.index(distances_from_segs.min)
      nearest_point = @cost_matrix[stop_index][index][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
      [index, nearest_point]
    end

    def index_of_line_segment_for_max_search(stop_index, min_index)
      unless @stop_segment_matching_candidates[stop_index].nil?
        @stop_segment_matching_candidates[stop_index].reject{|locator_and_cost,index| index < min_index }.sort_by{|locator_and_cost,index| locator_and_cost[1] }[0][1]
      end
    end

    def calculate_distances(rsp, stops=nil)
      if stops.nil?
        stop_hash = Hash[Stop.find_by_onestop_ids!(rsp.stop_pattern).map { |s| [s.onestop_id, s] }]
        stops = rsp.stop_pattern.map{|s| stop_hash.fetch(s) }
      end
      if stops.map(&:onestop_id).uniq.size == 1
        rsp.stop_distances = Array.new(stops.size).map{|i| 0.0}
        return rsp.stop_distances
      end
      rsp.stop_distances = Array.new(rsp.stop_pattern.size)
      route_line_as_cartesian = self.class.cartesian_cast(rsp[:geometry])
      num_segments = route_line_as_cartesian._segments.size
      @cost_matrix = self.class.compute_cost_matrix(stops, route_line_as_cartesian)
      best_possible_matching_segments_for_stops(route_line_as_cartesian, stops)

      first_stop_outlier = assign_first_stop_distance(rsp, route_line_as_cartesian, stops[0][:geometry], self.class.cartesian_cast(stops[0][:geometry]))
      outlier_indexes = []

      a = 0
      b = 0
      stops.each_with_index do |current_stop, i|
        current_stop_as_spherical = current_stop[:geometry]
        current_stop_as_cartesian = self.class.cartesian_cast(current_stop_as_spherical)
        c = num_segments - 1

        if i == stops.size - 1
          assign_last_stop_distance(rsp, route_line_as_cartesian, a)
        else
          next if i == 0 and first_stop_outlier
          if i < stops.size - 1
            c = index_of_line_segment_for_max_search(i+1, a) || num_segments - 1
          end
          b, nearest_point = index_of_line_segment_with_nearest_point(i, a, c)

          equivalent_stops = i > 0 && current_stop.onestop_id.eql?(stops[i-1].onestop_id) || current_stop[:geometry].eql?(stops[i-1][:geometry])
          unless equivalent_stops
            try_again = false
            if i > 0 && a == b && @cost_matrix[i][b][0].distance_on_segment < @cost_matrix[i-1][a][0].distance_on_segment
              a += 1
              try_again = true
            end
            b, nearest_point = index_of_line_segment_with_nearest_point(i, a, c) if try_again && a<=c
          end

          if OutlierStop.outlier_stop_from_precomputed_geometries(current_stop_as_spherical, current_stop_as_cartesian, route_line_as_cartesian)
            outlier_indexes << i
          else
            rsp.stop_distances[i] = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, b)
          end
          a = b
        end
      end

      outlier_indexes.each do |j|
        if j == 0
          rsp.stop_distances[j] = 0.0
        elsif j == rsp.stop_distances.size - 1
          rsp.stop_distances[rsp.stop_distances.size - 1] = rsp[:geometry].length
        else
          rsp.stop_distances[j] = rsp.stop_distances[j-1] + stops[j-1][:geometry].distance(stops[j+1][:geometry])/2.0
        end
      end
      rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
    end
  end

  class GTFSShapeDistanceTraveled < DistanceCalculation
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
      route_line_as_cartesian = self.cartesian_cast(rsp[:geometry])
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
