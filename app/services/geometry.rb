module Geometry
  module Lib
    def cartesian_cast(geometry)
      cartesian_factory = RGeo::Cartesian::Factory.new(srid: 4326)
      RGeo::Feature.cast(geometry, cartesian_factory)
    end

    def self.line_string(points)
      RouteStopPattern::GEOFACTORY.line_string(
        points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
      )
    end

    def self.set_precision(points, precision)
      points.map { |c| c.map { |n| n.round(precision) } }
    end
  end

  class OutlierStop
    extend Lib

    OUTLIER_THRESHOLD = 100 # meters

    def self.outlier_stop(stop, rsp)
      stop_as_spherical = stop[:geometry]
      stop_as_cartesian = cartesian_cast(stop_as_spherical)
      line_geometry_as_cartesian = cartesian_cast(rsp[:geometry])
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

    def self.stop_before_geometry(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      line_geometry_as_cartesian.before?(stop_as_cartesian) || OutlierStop.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.stop_after_geometry(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
      line_geometry_as_cartesian.after?(stop_as_cartesian) || OutlierStop.outlier_stop_from_precomputed_geometries(stop_as_spherical, stop_as_cartesian, line_geometry_as_cartesian)
    end

    def self.nearest_point_on_line(locators, nearest_seg_index)
      locators[nearest_seg_index].interpolate_point(RGeo::Cartesian::Factory.new(srid: 4326))
    end

    def self.index_of_line_segment_with_nearest_point(locators, s, e, point)
      # the method is going forward along the line's direction to find the closest match.

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
        unless i == locators[s..e].size - 1
          next_locators = locators[s..e][i+1..-1].reject{|loc| loc.segment.single_point? }
          closer_match = nil
          next_locators.each_with_index do |loc, j|
            next_seg_dist = loc.interpolate_point(Stop::GEOFACTORY).distance(point)
            if next_seg_dist <= dist
              closer_match = j
              dist = next_seg_dist
            else
              break
            end
          end
          i = locators[s..e].index(next_locators[closer_match]) unless closer_match.nil?
        end
        return s + i
      end

      # If no match is found within the threshold, just take closest match wthin the search range.
      self.index_of_line_segment_with_nearest_point_global(locators, s, e)
    end

    def self.index_of_line_segment_with_nearest_point_global(locators, start, stop)
      # 'global' meaning within the start and stop range
      distances_from_segs = locators[start..stop].map(&:distance_from_segment)
      start + distances_from_segs.index(distances_from_segs.min)
    end

    def self.distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, nearest_seg_index)
      if nearest_seg_index == 0
        points = [route_line_as_cartesian.coordinates[0], [nearest_point.x, nearest_point.y]]
      else
        points = route_line_as_cartesian.line_subset(0, nearest_seg_index-1).coordinates << [nearest_point.x, nearest_point.y]
      end
      Geometry::Lib.line_string(points).length
    end

    def self.distance_to_nearest_point_on_line(stop_point_spherical, nearest_point)
      stop_point_spherical.distance(RGeo::Feature.cast(nearest_point, RouteStopPattern::GEOFACTORY))
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
          route_line_as_cartesian = self.cartesian_cast(rsp[:geometry])
          stop = tl_stops[i]
          nearest_point_on_line = route_line_as_cartesian.closest_point_on_segment(self.cartesian_cast(stop[:geometry]), seg_index)
          rsp.stop_distances << distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point_on_line, seg_index)
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
      route_line_as_cartesian = self.cartesian_cast(rsp[:geometry])
      num_segments = route_line_as_cartesian.coordinates.size - 1
      a = 0
      b = 0
      c = num_segments - 1
      last_stop_after_geom = self.stop_after_geometry(stops[-1][:geometry], self.cartesian_cast(stops[-1][:geometry]), route_line_as_cartesian)
      previous_stop_before_geom = false
      stops.each_index do |i|
        current_stop = stops[i]
        current_stop_as_spherical = current_stop[:geometry]
        current_stop_as_cartesian = self.cartesian_cast(current_stop_as_spherical)
        if i == 0 && self.stop_before_geometry(current_stop_as_spherical, current_stop_as_cartesian, route_line_as_cartesian)
          previous_stop_before_geom = true
          rsp.stop_distances << 0.0
        elsif i == stops.size - 1 && last_stop_after_geom
          rsp.stop_distances << rsp[:geometry].length
        else
          if (i + 1 <= stops.size - 1)
            next_stop = stops[i+1]
            next_stop_as_cartesian = self.cartesian_cast(next_stop[:geometry])
            next_stop_locators = route_line_as_cartesian.locators(next_stop_as_cartesian)
            next_candidates = next_stop_locators[a..num_segments-1].map(&:distance_from_segment)
            c = a + next_candidates.index(next_candidates.min)
          else
            c = num_segments - 1
          end

          locators = route_line_as_cartesian.locators(current_stop_as_cartesian)
          b = index_of_line_segment_with_nearest_point(locators, a, c, current_stop_as_cartesian)
          nearest_point = nearest_point_on_line(locators, b)

          # The next stop's match may be too early and restrictive, so allow more segment possibilities
          if distance_to_nearest_point_on_line(current_stop_as_spherical, nearest_point) > FIRST_MATCH_THRESHOLD
            if (i + 2 <= stops.size - 1)
              next_stop = stops[i+2]
              next_stop_as_cartesian = self.cartesian_cast(next_stop[:geometry])
              next_stop_locators = route_line_as_cartesian.locators(next_stop_as_cartesian)
              next_candidates = next_stop_locators[a..num_segments-1].map(&:distance_from_segment)
              c = a + next_candidates.index(next_candidates.min)
            else
              c = num_segments - 1
            end
            b = index_of_line_segment_with_nearest_point(locators, a, c, current_stop_as_cartesian)
            nearest_point = nearest_point_on_line(locators, b)
          end

          distance = distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, b)
          if (i!=0)
            if self.stop_before_geometry(current_stop_as_spherical, current_stop_as_cartesian, route_line_as_cartesian) && previous_stop_before_geom
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
                  b = index_of_line_segment_with_nearest_point(locators, a, c, current_stop_as_cartesian)
                  nearest_point = nearest_point_on_line(locators, b)
                  distance = distance_along_line_to_nearest_point(route_line_as_cartesian, nearest_point, b)
                end
              end
              previous_stop_before_geom = false
            end
          end

          if !OutlierStop.test_distance(distance_to_nearest_point_on_line(current_stop_as_spherical, nearest_point))
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
end
