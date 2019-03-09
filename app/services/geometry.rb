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

    attr_accessor :stop_segment_matching_candidates,
                  :stop_locators,
                  :best_single_segment_match_for_stops

    def initialize(spherical_shape, spherical_stop_points, cartesian_shape: nil)
      @shape_length = spherical_shape.length

      @distances = Array.new(spherical_stop_points.size)
      @cartesian_shape = cartesian_shape || self.class.cartesian_cast(spherical_shape)
      @pulverized_shape = nil

      @cartesian_stop_points = spherical_stop_points.map do |point|
        self.class.cartesian_cast(point)
      end

      @spherical_stop_points = spherical_stop_points

      @stop_locators = self.class.stop_locators(@cartesian_stop_points, @cartesian_shape)
    end

    def self.stop_locators(cartesian_stop_points, cartesian_shape)
      cartesian_stop_points.map do |point|
        locators = cartesian_shape.locators(point)
        locators.map{|locator| [locator, locator.distance_from_segment]}
      end
    end

    def self.cost_matrix(cartesian_stop_points, cartesian_shape)
      self.stop_locators(cartesian_stop_points, cartesian_shape)
        .map { |locator_with_distances| locator_with_distances.map{ |l| l[1] } }
    end

    def fallback_distances
      self.class.fallback_distances(@cartesian_shape, @cartesian_stop_points, @stop_locators)
    end

    def self.fallback_distances(cartesian_shape, cartesian_stop_points, stop_locators=nil)
      if stop_locators.nil?
        stop_locators = self.class.stop_locators(cartesian_stop_points, cartesian_shape)
      end

      # a naive assigment of stops to closest segment.
      stop_locators.map do |m|
        locator_and_cost, i = m.each_with_index.min_by{|locator_and_cost,i| locator_and_cost[1] }
        closest_point = locator_and_cost[0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
        LineString.distance_along_line_to_nearest_point(cartesian_shape, closest_point, i)
      end
    end

    def self.straight_line_distances(spherical_stop_points)
      # stop distances on straight lines from stop to stop
      stop_distances = [0.0]
      total_distance = 0.0
      spherical_stop_points.each_cons(2) do |stop1, stop2|
        total_distance += stop1.distance(stop2)
        stop_distances << total_distance
      end
      stop_distances
    end

    def self.pulverize_shape(cartesian_shape, e=0.001)
      # ensures line has no segments with length greater than e
      new_points = cartesian_shape._segments.map do |segment|
        if segment.length > e
          num_new_points = segment.length.fdiv(e).floor
          sub_l = segment.length.fdiv(num_new_points + 1)
          prop_x = segment.dx.fdiv(segment.length)
          prop_y = segment.dy.fdiv(segment.length)
          [segment.s] +
          Array.new(num_new_points) do |i|
            dy = sub_l*(1+i)*prop_y
            dx = sub_l*(1+i)*prop_x
            RGeo::Cartesian::Factory.new(srid: 4326).point(
              segment.s.x + dx,
              segment.s.y + dy
            )
          end +
          [segment.e]
        else
          [segment.s, segment.e]
        end
      end.flatten

      return cartesian_shape if new_points.size == cartesian_shape.points.size

      RGeo::Cartesian::Factory.new(srid: 4326).line_string(new_points)
    end

    def pulverize_shape(e=0.001)
      @pulverized_shape = self.class.pulverize_shape(@cartesian_shape, e)
      @stop_locators = self.class.stop_locators(@cartesian_stop_points, @pulverized_shape)
      [@stop_locators, @pulverized_shape]
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
          @cartesian_shape,
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
        @cartesian_shape,
        @cartesian_stop_points,
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

  class GTFSShapeDistanceTraveled
    extend Lib

    DISTANCE_PRECISION = 1

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

  class DynamicNOpaAlgorithm < DistanceCalculation
    def calculate_distances(skip_stops=[])
      @skip_stops = skip_stops
      computable_stop_positions = (0...@cartesian_stop_points.size).to_a - @skip_stops
      stops = @cartesian_stop_points.values_at(*computable_stop_positions)

      cartesian_shape = @pulverized_shape || @cartesian_shape

      cost_matrix = self.class.cost_matrix(
        stops,
        cartesian_shape
      )

      distance_calculator = NOpa::DynamicAlgorithm.new(
        cost_matrix,
        costs: true
      )
      cost, assignments = distance_calculator.compute

      @best_single_segment_match_for_stops = Array.new(@cartesian_stop_points.size).each_with_index.map do |a, i|
        next unless computable_stop_positions.include?(i)
        a = assignments[computable_stop_positions.index(i)]
      end
      Array.new(@cartesian_stop_points.size).each_with_index.map do |a, i|
        next unless computable_stop_positions.include?(i)
        j = computable_stop_positions.index(i)
        t = assignments[j]
        locator = @stop_locators[i][t][0]
        LineString.distance_along_line_to_nearest_point(
          cartesian_shape,
          locator.interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),
          t
        )
      end
    end
  end

  class TLDistances
    # This is where Transitland applies rules on how to handle
    # outliers, which core algorithm(s) to use, how to round, etc.

    extend Lib

    DISTANCE_PRECISION = 1

    def initialize(rsp, stops=nil)
      @rsp = rsp

      if stops.nil?
        @stops = Stop.find_by_sql("SELECT s.onestop_id, s.geometry FROM current_stops s JOIN unnest( ARRAY[#{@rsp.stop_pattern.map{|s| "'#{s}'"}.join(',')}] ) WITH ORDINALITY t(id, ord) ON t.id=s.onestop_id ORDER BY t.ord")
      else
        @stops = stops
      end

      @rsp.stop_distances = Array.new(@stops.size)

      @route_line_length = @rsp[:geometry].length

      @cartesian_shape = self.class.cartesian_cast(@rsp[:geometry])

      @spherical_stop_points = @stops.map { |stop| stop.geometry_centroid }

      @cartesian_stop_points = @spherical_stop_points.map do |point|
        self.class.cartesian_cast(point)
      end
    end

    def stop_before_geometry?(stop_as_cartesian)
      @cartesian_shape.before?(stop_as_cartesian) ||
      OutlierStop.outlier_stop?(@cartesian_shape, stop_as_cartesian)
    end

    def stop_after_geometry?(stop_as_cartesian)
      @cartesian_shape.after?(stop_as_cartesian) ||
      OutlierStop.outlier_stop?(@cartesian_shape, stop_as_cartesian)
    end

    def assign_first_stop_distance(computed_distances)
      # compare the second stop's closest segment point to the first. If the first stop's point
      # is after the second, then it has to be set to 0.0 because the line geometry
      # is likely to be too short by not starting at or near the first stop.

      locator_and_cost, nearest_index = @stop_locators[0].each_with_index.min_by{|locator_and_cost, i| locator_and_cost[1]}
      closest_point = locator_and_cost[0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))

      closest_dist = LineString.distance_along_line_to_nearest_point(
        @cartesian_shape,
        closest_point,
        nearest_index
      )

      if closest_dist > (computed_distances[1..-1].detect{|d| !d.nil?} || @route_line_length)
        0.0
      else
        closest_dist
      end
    end

    def assign_last_stop_distance
      # compare the last stop's closest segment point to the penultimate. If the last stop's point
      # is before the penultimate, then it has to be set to the length of the line geometry, as the line
      # is likely to be too short by not coming up to the last stop.

      locator_and_cost, nearest_index = @stop_locators[-1].each_with_index.min_by{|locator_and_cost, i| locator_and_cost[1]}
      closest_point = locator_and_cost[0].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))

      closest_dist = LineString.distance_along_line_to_nearest_point(
        @cartesian_shape,
        closest_point,
        nearest_index
      )

      if closest_dist < (@rsp.stop_distances[0..-2].reverse.detect{|d| !d.nil?} || 0.0)
        @route_line_length
      else
        closest_dist
      end
    end

    def calculate_distances(try_first_pass: false)
      if @stops.map(&:onestop_id).uniq.size == 1
        @rsp.stop_distances = Array.new(@stops.size).map{|i| 0.0}
        return @rsp.stop_distances
      end

      @distance_calculator = Geometry::DynamicNOpaAlgorithm.new(
        @rsp[:geometry],
        @spherical_stop_points,
        cartesian_shape: @cartesian_shape
      )

      @stop_locators = @distance_calculator.stop_locators

      compute_skip_stops

      if try_first_pass && !@distance_calculator.complex?(@skip_stops)
        # the first pass heuristic looks for the condition where each stop already matches
        # to a segment that maintains distance order. It may not be optimal.
        prepare_stop_distances(
          @distance_calculator.first_pass_distances(@skip_stops),
          @distance_calculator.first_pass.map{ |l| l[1] unless l.nil? }
        )
        return @rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
      end

      begin
        compute_skip_stops
        @stop_locators, @cartesian_shape = @distance_calculator.pulverize_shape

        stop_distances = @distance_calculator.calculate_distances(@skip_stops)

        prepare_stop_distances(
          stop_distances,
          @distance_calculator.best_single_segment_match_for_stops
        )

        if @distance_calculator.invalid?
          # something is wrong, so we'll fake distances by using the closest match. It should throw distance quality issues later on.
          @rsp.stop_distances = Geometry::DistanceCalculation.new(@rsp[:geometry], @spherical_stop_points).fallback_distances
        end

        @rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
      rescue => e
        log("Could not calculate distances for Route Stop Pattern: #{@rsp.onestop_id}. Error: #{e}")
        @rsp.stop_distances = Geometry::DistanceCalculation.new(@rsp[:geometry], @spherical_stop_points).fallback_distances
        @rsp.stop_distances.map!{ |distance| distance.round(DISTANCE_PRECISION) }
      end
    end

    def prepare_stop_distances(computed_distances, computed_segment_matches)
      @rsp.stop_distances.each_with_index do |distance, i|
        if @skip_stops.include?(i)
          if i == 0
            @rsp.stop_distances[i] = assign_first_stop_distance(computed_distances)
          elsif i == @rsp.stop_distances.size - 1
            @rsp.stop_distances[i] = assign_last_stop_distance
          else
            # interpolate between the previous and next stop distances
            @rsp.stop_distances[i] = (
              @rsp.stop_distances[i-1] +
              (computed_distances[i+1..-1].detect{|d| !d.nil?} || @route_line_length)
            ).fdiv(2)
          end
        else
          @rsp.stop_distances[i] = computed_distances[i]
        end
      end
    end

    def compute_skip_stops
      @skip_stops = []
      @skip_stops << 0 if stop_before_geometry?(@cartesian_stop_points[0])
      @cartesian_stop_points[1...-1].each_with_index do |point, i|
        @skip_stops << i + 1 if OutlierStop.outlier_stop?(@cartesian_shape, point)
      end
      @skip_stops << @cartesian_stop_points.size - 1 if stop_after_geometry?(@cartesian_stop_points[-1])
    end
  end
end
