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

    def self.nearest_point_on_line(locators, nearest_seg_index)
      locators[nearest_seg_index].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
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

    def self.rsp_max_dist(rsp)
      geometry_length = rsp[:geometry].length
      max_dist = geometry_length
      line_geometry_as_cartesian = OutlierStop.cartesian_cast(rsp[:geometry])
      first_stop = Stop.find_by_onestop_id!(rsp.stop_pattern.first)
      first_stop_as_cartesian = OutlierStop.cartesian_cast(first_stop[:geometry])
      last_stop = Stop.find_by_onestop_id!(rsp.stop_pattern.last)
      last_stop_as_cartesian = OutlierStop.cartesian_cast(last_stop[:geometry])
      if rsp.stop_distances.first == 0 && Geometry::DistanceCalculation.stop_before_geometry(first_stop[:geometry],first_stop_as_cartesian,line_geometry_as_cartesian)
        max_dist += rsp[:geometry].start_point.distance(first_stop[:geometry])
      end
      if Geometry::DistanceCalculation.stop_after_geometry(last_stop[:geometry],last_stop_as_cartesian,line_geometry_as_cartesian)
        max_dist += rsp[:geometry].end_point.distance(last_stop[:geometry])
      end
      max_dist
    end

    def self.stop_before_geometry(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      line_geometry_as_cartesian.before?(stop_as_cartesian) || OutlierStop.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.stop_after_geometry(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      line_geometry_as_cartesian.after?(stop_as_cartesian) || OutlierStop.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.index_of_line_segment_with_nearest_point(locators, start, stop)
      distances_from_segs = locators[start..stop].map(&:distance_from_segment)
      index = start + distances_from_segs.index(distances_from_segs.min)
      nearest_point = LineString.nearest_point_on_line(locators, index)
      [index, nearest_point]
    end

    def self.index_of_line_segment_with_nearest_point_next_stop(route_line_as_cartesian, tl_stops, test_stop_index, start_seg_index, num_segments)
      if (test_stop_index <= tl_stops.size - 1)
        next_stop_as_cartesian = self.cartesian_cast(tl_stops[test_stop_index][:geometry])
        next_stop_locators = route_line_as_cartesian.locators(next_stop_as_cartesian)
        index, nearest_point = self.index_of_line_segment_with_nearest_point(next_stop_locators, start_seg_index, num_segments - 1)
        return [index, nearest_point]
      else
        return [num_segments - 1, nil]
      end
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
      num_segments = route_line_as_cartesian.coordinates.size - 1
      a = 0
      b = 0
      c = num_segments - 1
      last_stop_after_geom = self.stop_after_geometry(stops[-1][:geometry], self.cartesian_cast(stops[-1][:geometry]), route_line_as_cartesian)
      stop_matched_inside_line = false
      extra_distance_before_line = 0.0
      stops.each_index do |i|
        current_stop = stops[i]
        current_stop_as_spherical = current_stop[:geometry]
        current_stop_as_cartesian = self.cartesian_cast(current_stop_as_spherical)
        locators = route_line_as_cartesian.locators(current_stop_as_cartesian)
        if i == 0 && self.stop_before_geometry(current_stop_as_spherical, current_stop_as_cartesian, route_line_as_cartesian)
          # compare the second stop's distance to the first. If the first stop's distance
          # is greater than the second, then it has to be set to 0.0 because the line geometry
          # is likely to be too short by not coming up to the first stop.
          c, next_nearest_point = self.index_of_line_segment_with_nearest_point_next_stop(route_line_as_cartesian, stops, i+1, a, num_segments)
          next_stop_distance = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian, next_nearest_point, c)
          b, nearest_point = self.index_of_line_segment_with_nearest_point(locators, a, c)
          current_stop_distance = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, b)
          if next_stop_distance > current_stop_distance
            rsp.stop_distances << current_stop_distance
          else
            rsp.stop_distances << 0.0
            extra_distance_before_line = stops[i][:geometry].distance(rsp[:geometry].start_point)
          end
        elsif i == stops.size - 1 && last_stop_after_geom
          # compare the last stop's computed distance to the second to last stop's distance. If the last stop has
          # a smaller distance, then the line geometry might be too short by not reaching the last stop. Its distance is set
          # to the length of the geometry.
          b, nearest_point = self.index_of_line_segment_with_nearest_point(locators, a, num_segments - 1)
          current_stop_distance = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, b)
          if rsp.stop_distances[i-1] > current_stop_distance
            extra_distance_after_line = stops[i][:geometry].distance(rsp[:geometry].end_point)
            rsp.stop_distances << rsp[:geometry].length + extra_distance_before_line + extra_distance_after_line
          else
            rsp.stop_distances << current_stop_distance + extra_distance_before_line
          end
        else
          c, next_nearest_point = self.index_of_line_segment_with_nearest_point_next_stop(route_line_as_cartesian, stops, i+1, a, num_segments)
          b, nearest_point = self.index_of_line_segment_with_nearest_point(locators, a, c)

          # The next stop's match may be too early and restrictive, so allow more segment possibilities
          if LineString.distance_to_nearest_point_on_line(current_stop_as_spherical, nearest_point) > FIRST_MATCH_THRESHOLD
            c, next_nearest_point = self.index_of_line_segment_with_nearest_point_next_stop(route_line_as_cartesian, stops, i+2, a, num_segments)
            b, nearest_point = self.index_of_line_segment_with_nearest_point(locators, a, c)
          end

          current_stop_distance = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, b)
          if (i!=0)
            equivalent_stop = stops[i].onestop_id.eql?(stops[i-1].onestop_id) || stops[i][:geometry].eql?(stops[i-1][:geometry])
            if !equivalent_stop
              # this can happen if this stop matches to the same segment as the previous
              if (current_stop_distance <= rsp.stop_distances[i-1]) && stop_matched_inside_line
                a += 1
                if (a == num_segments - 1)
                  current_stop_distance = rsp[:geometry].length
                elsif (a > c)
                  # Something might be wrong with the RouteStopPattern.
                else
                  b, nearest_point = self.index_of_line_segment_with_nearest_point(locators, a, c)
                  current_stop_distance = LineString.distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, b)
                end
              end
            end
          end

          # exhausting the search before outlier stop test
          if !OutlierStop.test_distance(LineString.distance_to_nearest_point_on_line(current_stop_as_spherical, nearest_point))
            if (i==0)
              rsp.stop_distances << 0.0
            elsif (i==stops.size-1)
              rsp.stop_distances << rsp[:geometry].length
            else
              # interpolate using half the distance between previous and next stop
              rsp.stop_distances << rsp.stop_distances[i-1] + stops[i-1][:geometry].distance(stops[i+1][:geometry])/2.0
            end
          else
            rsp.stop_distances << current_stop_distance + extra_distance_before_line
          end
          stop_matched_inside_line = true if !nearest_point.eql?(route_line_as_cartesian.points.first)
          a = b
        end
      end # end stop pattern loop
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
