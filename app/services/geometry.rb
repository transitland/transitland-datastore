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

    def initialize(stop, rsp)
      @line_geometry_as_cartesian = self.class.cartesian_cast rsp[:geometry]
      @stop_as_cartesian = self.class.cartesian_cast stop.geometry_centroid
    end

    def outlier_stop?
      self.class.outlier_stop?(@line_geometry_as_cartesian, @stop_as_cartesian)
    end

    # NOTE: The determination for outliers during distance calculation
    # may be different than the one for quality checks.

    OUTLIER_THRESHOLD = 100 # meters

    def self.outlier_stop?(line_geometry_as_cartesian, stop_as_cartesian)
      closest_point_as_cartesian = line_geometry_as_cartesian.closest_point(stop_as_cartesian)
      closest_point_as_spherical = RGeo::Feature.cast(closest_point_as_cartesian, RouteStopPattern::GEOFACTORY)
      stop_as_spherical = RGeo::Feature.cast(stop_as_cartesian, RouteStopPattern::GEOFACTORY)
      stop_as_spherical.distance(closest_point_as_spherical) > OUTLIER_THRESHOLD
    end
  end

  class DistanceCalculation
    extend Lib

    DISTANCE_PRECISION = 1

    attr_accessor :stop_segment_matching_candidates,
                  :stop_locators,
                  :best_single_segment_match_for_stops

    def initialize(rsp, stops=nil, route_line_as_cartesian: nil)
      if stops.nil?
        @stops = rsp.stop_pattern.map do |onestop_id|
          Stop.find_by_onestop_id!(onestop_id)
        end
      else
        @stops = stops
      end
      @rsp = rsp
      @route_line_length = rsp[:geometry].length

      @rsp.stop_distances = Array.new(@stops.size)
      @route_line_as_cartesian = route_line_as_cartesian || self.class.cartesian_cast(rsp[:geometry])

      @cartesian_stops = @stops.map do |stop|
        self.class.cartesian_cast(stop.geometry_centroid)
      end

      @spherical_stops = @stops.map { |stop| stop.geometry_centroid }

      @stop_locators = self.class.stop_locators(@cartesian_stops, @route_line_as_cartesian)
    end

    def self.stop_locators(cartesian_stops, route_line_as_cartesian)
      cartesian_stops.map do |cartesian_stop|
        locators = route_line_as_cartesian.locators(cartesian_stop)
        locators.map{|locator| [locator, locator.distance_from_segment]}
      end
    end

    def self.cost_matrix(cartesian_stops, route_line_as_cartesian)
      self.stop_locators(cartesian_stops, route_line_as_cartesian)
        .map { |locator_with_distances| locator_with_distances.map{ |l| l[1] } }
    end

    def self.fallback_distances(route_line_as_cartesian, cartesian_stops, stop_locators=nil)
      if stop_locators.nil?
        stop_locators = self.class.stop_locators(cartesian_stops, route_line_as_cartesian)
      end

      # a naive assigment of stops to closest segment.
      stop_locators.map do |m|
        locator_and_cost, i = m.each_with_index.min_by{|locator_and_cost,i| locator_and_cost[1] }
        closest_point = locator_and_cost[0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
        LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,closest_point,i)
      end
    end

    def self.straight_line_distances(spherical_stops)
      # stop distances on straight lines from stop to stop
      stop_distances = [0.0]
      total_distance = 0.0
      spherical_stops.each_cons(2) do |stop1, stop2|
        total_distance += stop1.distance(stop2)
        stop_distances << total_distance
      end
      stop_distances
    end

    def self.pulverize_line(cartesian_line, e=0.001)
      # ensures line has no segments with length greater than e
      new_points = cartesian_line._segments.map do |segment|
        if segment.length > e
          num_new_points = segment.length.fdiv(e).floor
          sub_l = segment.length.fdiv(num_new_points + 1)
          prop_x = segment.dx.fdiv(segment.length)
          prop_y = segment.dy.fdiv(segment.length)
          [segment.s] +
          Array.new(num_new_points) do |i|
            dy = sub_l*(1+i)*prop_y
            dx = sub_l*(1+i)*prop_x
            self.cartesian_cast(
              RouteStopPattern::GEOFACTORY.point(segment.s.x + dx, segment.s.y + dy)
            )
          end +
          [segment.e]
        else
          [segment.s, segment.e]
        end
      end.flatten

      return cartesian_line if new_points.size == cartesian_line.points.size

      self.cartesian_cast(RouteStopPattern::GEOFACTORY.line_string(new_points))
    end

    def first_pass(skip_stops=[])
      @first_pass ||= @stop_locators.each_with_index.map do |locators, i|
        next if skip_stops.include?(i)
        min = locators.min_by { |lc| lc[1] }
        [min[0], locators.index(min)]
      end
    end

    def first_pass_distances(skip_stops=[])
      first_pass(skip_stops).each_with_index.map do |locator_and_index, i|
        next if skip_stops.include?(i)
        closest_point = locator_and_index[0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
        LineString.distance_along_line_to_nearest_point(
          @route_line_as_cartesian,
          closest_point,
          locator_and_index[1]
        )
      end
    end

    def complex?(skip_stops=[])
      first_pass(skip_stops).compact.map {|l| l[1] }
        .each_cons(2)
        .any? {|s1, s2| s1 >= s2 }
    end

    def fallback_distances
      self.class.fallback_distances(
        @route_line_as_cartesian,
        @cartesian_stops,
        @stop_locators
      )
    end

    def invalid?
      matches_invalid?
    end

    private

    def matches_invalid?
      @best_single_segment_match_for_stops.nil? ||
      @best_single_segment_match_for_stops.each_with_index.any? do |b, i|
        b.nil? && !@skip_stops.include?(i)
      end ||
      @best_single_segment_match_for_stops.each_cons(2).any? do |m1, m2|
        m1.nil? && m2.nil? && @best_single_segment_match_for_stops.size != 2
      end
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
      end
      return false
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
            locators = route_line_as_cartesian.locators(self.cartesian_cast(stop.geometry_centroid))
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

  class DynamicOpapWcAlgorithm < DistanceCalculation
    def calculate_distances(skip_stops=[])
      @skip_stops = skip_stops
      computable_stop_positions = (0...@cartesian_stops.size).to_a - @skip_stops
      stops = @cartesian_stops.values_at(*computable_stop_positions)

      cost_matrix = self.class.cost_matrix(
        stops,
        @route_line_as_cartesian
      )

      distance_calculator = OpapWc::DynamicAlgorithm.new(
        cost_matrix,
        costs: true
      )
      cost, assignments = distance_calculator.compute

      @best_single_segment_match_for_stops = Array.new(@cartesian_stops.size).each_with_index.map do |a, i|
        next unless computable_stop_positions.include?(i)
        a = assignments[computable_stop_positions.index(i)]
      end
      Array.new(@cartesian_stops.size).each_with_index.map do |a, i|
        next unless computable_stop_positions.include?(i)
        j = computable_stop_positions.index(i)
        t = assignments[j]
        locator = @stop_locators[i][t][0]
        LineString.distance_along_line_to_nearest_point(
          @route_line_as_cartesian,
          locator.interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),
          t
        )
      end
    end
  end

  class MetaDistances < DistanceCalculation
    def stop_before_geometry?(line_geometry_as_cartesian, stop_as_cartesian)
      line_geometry_as_cartesian.before?(stop_as_cartesian) ||
      OutlierStop.outlier_stop?(line_geometry_as_cartesian, stop_as_cartesian)
    end

    def stop_after_geometry?(line_geometry_as_cartesian, stop_as_cartesian)
      line_geometry_as_cartesian.after?(stop_as_cartesian) ||
      OutlierStop.outlier_stop?(line_geometry_as_cartesian, stop_as_cartesian)
    end

    def assign_first_stop_distance(route_line_as_cartesian, first_stop_as_cartesian)
      # compare the second stop's closest segment point to the first. If the first stop's point
      # is after the second, then it has to be set to 0.0 because the line geometry
      # is likely to be too short by not starting at or near the first stop.
      first_stop_locator_and_index = @stop_locators[0].each_with_index.min_by{|locator_and_cost, i| locator_and_cost[1]}
      second_stop_locator_and_index = @stop_locators[1].each_with_index.min_by{|locator_and_cost, i| locator_and_cost[1]}
      first_stop_seg_match = first_stop_locator_and_index[1]
      second_stop_seg_match = second_stop_locator_and_index[1]
      if (first_stop_seg_match < second_stop_seg_match) ||
        ((first_stop_seg_match == second_stop_seg_match) &&
          (first_stop_locator_and_index[0][0].distance_on_segment < second_stop_locator_and_index[0][0].distance_on_segment))
        return LineString.distance_along_line_to_nearest_point(
          route_line_as_cartesian,
          first_stop_locator_and_index[0][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),
          first_stop_locator_and_index[1]
        )
      else
        return 0.0
      end
    end

    def assign_last_stop_distance(route_line_as_cartesian, penultimate_match)
      # compare the last stop's closest segment point to the penultimate. If the last stop's point
      # is before the penultimate, then it has to be set to the length of the line geometry, as the line
      # is likely to be too short by not coming up to the last stop.
      if penultimate_match.nil?
        return @route_line_length
      else
        last_stop_locator_and_index = @stop_locators[-1].each_with_index.select do |locator_and_cost, i|
          i >= penultimate_match
        end.min_by do |locator_and_cost, i|
          locator_and_cost[1]
        end
        if last_stop_locator_and_index[1] > penultimate_match ||
          (last_stop_locator_and_index[1] == penultimate_match) &&
          (last_stop_locator_and_index[0][0].distance_on_segment > @stop_locators[-2][penultimate_match][0].distance_on_segment)
          return LineString.distance_along_line_to_nearest_point(
            route_line_as_cartesian,
            last_stop_locator_and_index[0][0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),
            last_stop_locator_and_index[1])
        else
          return @route_line_length
        end
      end
    end

    def calculate_distances
      if @stops.map(&:onestop_id).uniq.size == 1
        @rsp.stop_distances = Array.new(@stops.size).map{|i| 0.0}
        return @rsp.stop_distances
      end

      @stop_locators = self.class.stop_locators(@cartesian_stops, @route_line_as_cartesian)
      compute_skip_stops
      if !complex?(@skip_stops)
        prepare_stop_distances(
          first_pass_distances(@skip_stops),
          first_pass.map{ |l| l[1] unless l.nil? }
        )
        return @rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
      end

      begin
        @route_line_as_cartesian = self.class.pulverize_line(@route_line_as_cartesian)
        @stop_locators = self.class.stop_locators(@cartesian_stops, @route_line_as_cartesian)
        compute_skip_stops
        distance_calculator = Geometry::DynamicOpapWcAlgorithm.new(
          @rsp,
          @stops,
          route_line_as_cartesian: @route_line_as_cartesian
        )
        stop_distances = distance_calculator.calculate_distances(@skip_stops)

        prepare_stop_distances(
          stop_distances,
          distance_calculator.best_single_segment_match_for_stops
        )

        if distance_calculator.invalid?
          # something is wrong, so we'll fake distances by using the closest match. It should throw distance quality issues later on.
          @rsp.stop_distances = self.class.fallback_distances(
            @route_line_as_cartesian,
            @cartesian_stops,
            @stop_locators
          )
        end

        @rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
      rescue => e
        log("Could not calculate distances for Route Stop Pattern: #{@rsp.onestop_id}. Error: #{e}")
        @rsp.stop_distances = Geometry::DistanceCalculation.new(@rsp, @stops).fallback_distances
      end
    end

    def prepare_stop_distances(computed_distances, computed_segment_matches)
      @rsp.stop_distances.each_with_index do |distance, i|
        if @skip_stops.include?(i)
          if i == 0
            @rsp.stop_distances[i] = assign_first_stop_distance(@route_line_as_cartesian, @cartesian_stops[i])
          elsif i == @rsp.stop_distances.size - 1
            @rsp.stop_distances[i] = assign_last_stop_distance(
              @route_line_as_cartesian,
              computed_segment_matches[i]
            )
          else
            # interpolate between the previous and next stop distances
            @rsp.stop_distances[i] = (
              @rsp.stop_distances[i-1] +
              (@rsp.stop_distances[i+1..-1].detect{|d| !d.nil?} || @route_line_length)
            ).fdiv(2)
          end
        else
          @rsp.stop_distances[i] = computed_distances[i]
        end
      end
    end

    def compute_skip_stops
      @skip_stops = []
      @skip_stops << 0 if stop_before_geometry?(@route_line_as_cartesian, @cartesian_stops[0])
      @cartesian_stops[1...-1].each_with_index do |cartesian_stop, i|
        @skip_stops << i + 1 if OutlierStop.outlier_stop?(@route_line_as_cartesian, cartesian_stop)
      end
      @skip_stops << @cartesian_stops.size - 1 if stop_after_geometry?(@route_line_as_cartesian, @cartesian_stops[-1])
    end
  end
end
