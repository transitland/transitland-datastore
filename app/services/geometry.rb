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

    def self.distance_to_nearest_point_on_line(stop_point_spherical, nearest_point)
      stop_point_spherical.distance(RGeo::Feature.cast(nearest_point, RouteStopPattern::GEOFACTORY))
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
      closest_point_as_cartesian = line_geometry_as_cartesian.closest_point(stop_as_cartesian)
      closest_point_as_spherical = RGeo::Feature.cast(closest_point_as_cartesian, RouteStopPattern::GEOFACTORY)
      stop_as_spherical.distance(closest_point_as_spherical) > OUTLIER_THRESHOLD
    end

    def self.test_distance(distance)
      distance < OUTLIER_THRESHOLD
    end
  end

  class DistanceCalculation
    extend Lib

    FIRST_MATCH_THRESHOLD = 25 # meters
    DISTANCE_PRECISION = 1

    attr_accessor :stop_segment_matching_candidates

    def self.stop_before_geometry(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      line_geometry_as_cartesian.before?(stop_as_cartesian) || OutlierStop.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.stop_after_geometry(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      line_geometry_as_cartesian.after?(stop_as_cartesian) || OutlierStop.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.best_possible_matching_segments_for_stops(route_line_as_cartesian, stops)
      @stop_segment_matching_candidates = []
      min_index = -1
      stops.each_with_index.map do |stop, i|
        stop_as_cartesian = self.cartesian_cast(stop[:geometry])
        locators = route_line_as_cartesian.locators(stop_as_cartesian)
        s = min_index > -1 ? min_index : 0
        matches = locators.each_with_index.select{|loc,i|
          i>=s && stop[:geometry].distance(loc.interpolate_point(Stop::GEOFACTORY)) < 150.0
        }
        if matches.to_a.empty?
          best_match = locators[s..-1].each_with_index.min_by{|loc,i| loc.distance_from_segment}
          max_index = s + best_match[1]
          min_index = max_index
          matches = [best_match]
        else
          max_index = matches.max_by{ |loc,i| i }[1]
          min_index = matches.min_by{ |loc,i| i }[1]
        end
        (i-1).downto(0).each do |j|
          @stop_segment_matching_candidates[j] = @stop_segment_matching_candidates[j].select{|m| m[1] <= max_index }
        end
        @stop_segment_matching_candidates[i] = matches
      end
    end

    def self.matching_segments(stops, stop_index, route_line_as_cartesian, start_seg_index)
      if stop_index == stops.size
        return []
      end
      stop_as_cartesian = self.cartesian_cast(stops[stop_index][:geometry])
      @stop_segment_matching_candidates[stop_index].sort_by{|dfs| dfs[0].distance_from_segment }.each do |dfs|
        index = dfs[1]
        next if index < start_seg_index
        forward_matches = self.matching_segments(stops, stop_index+1, route_line_as_cartesian, index)
        unless forward_matches.nil?
          forward_matches = [index].concat forward_matches
          # if forward_matches.each_cons(2).each_with_index.all? {|m,j| m[1] > m[0] || ((m[1] == m[0]) && @stop_segment_matching_candidates[stop_index+j].detect{|s| s[1] == m[0]}[0].distance_on_segment < @stop_segment_matching_candidates[stop_index+j+1].detect{|s| s[1] == m[1]}[0].distance_on_segment) }
            return forward_matches
          # end
        end
      end
      return nil
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
      route_line_as_cartesian = self.cartesian_cast(rsp[:geometry])
      self.best_possible_matching_segments_for_stops(route_line_as_cartesian, stops)
      best_segment_matches_for_stops = self.matching_segments(stops, 0, route_line_as_cartesian, 0)
      stops.each_with_index do |stop, i|
        locator = route_line_as_cartesian._segments[best_segment_matches_for_stops[i]].locator(stop[:geometry])
        rsp.stop_distances << LineString.distance_along_line_to_nearest_point(route_line_as_cartesian,locator.interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326)),best_segment_matches_for_stops[i])
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
