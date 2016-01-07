RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  config.register(RGeo::Geographic.spherical_factory(srid: 4326))
end

# monkey patch modified from:
#https://github.com/rgeo/rgeo/issues/99
module RGeo
  module Cartesian
    module LineStringMethods
      def locate_point(target)
        distance_on_line(target) / length
      end

      def distance_on_line(target)
        nearest_locator = nearest_locator(target)
        nearest_locator.distance_on_segment + distance_from_departure_to_segment(nearest_locator.segment)
      end

      def split_at_point(target)
        nearest_locator = nearest_locator(target)
        index = _segments.index(nearest_locator.segment)
        seg_point = nearest_locator.interpolate_point(factory)
        if index == 0 && seg_point.eql?(_segments[0].s)
          return [nil, factory.line_string([_segments[0].s] + _segments.map {|s| s.e})]
        elsif index == (_segments.length - 1) && seg_point.eql?(_segments[index].e)
          return [factory.line_string([_segments[0].s] + _segments.map {|s| s.e}), nil]
        end
        points1 = [_segments[0].s] + _segments[0...index].map {|s| s.e} + [seg_point]
        points2 = _segments[index..-1].map {|s| s.e}
        if !seg_point.eql?(_segments[index].e)
          points2.unshift(seg_point)
        end
        [factory.line_string(points1), factory.line_string(points2)]
      end

      def distance_from_departure_to_segment(segment)
        index = _segments.index(segment)
        _segments[0...index].inject(0.0){ |sum_, seg_| sum_ + seg_.length }
      end

      def nearest_locator(target)
        locators(target).min_by(&:distance_from_segment)
      end

      def locators(point)
        _segments.collect { |segment| segment.locator(point) }
      end

      def interpolate_point(location)
        return points.last if location >= 1
        return points.first if location <= 0

        distance_on_line_string = location * length

        line_distance_at_departure = line_distance_at_arrival = 0
        segment = _segments.find do |segment|
          line_distance_at_arrival += segment.length
          line_distance_at_departure = line_distance_at_arrival - segment.length
          line_distance_at_arrival > distance_on_line_string
        end

        return nil if segment.blank?

        location_on_segment = (distance_on_line_string - line_distance_at_departure) / segment.length
        dx_location, dy_location = segment.dx * location_on_segment, segment.dy * location_on_segment
        factory.point(segment.s.x + dx_location, segment.s.y + dy_location)
      end
    end

    class Segment
      def locator(target)
        PointLocator.new target, self
      end
    end

    class PointLocator
      include Math

      attr_reader :target, :segment

      def initialize(target, segment)
        @target = target
        @segment = segment
        raise "Target is not defined" unless target
      end

      def distance_on_segment
        # TODO: cache
        segment.tproj(target) * segment.length
      end

      def distance_from_segment
        return 0 if segment.contains_point?(target)
        dist = distance_on_segment
        return target.distance(segment.e) if dist >= segment.length
        return target.distance(segment.s) if dist <= 0
        ::Math.sqrt( target_distance_from_departure ** 2 - dist ** 2 )
      end

      def target_distance_from_departure
        segment.s.distance target
      end

      def interpolate_point(factory)
        location = distance_on_segment / segment.length
        return segment.e if location >= 1
        return segment.s if location <= 0
        dx_location, dy_location = segment.dx * location, segment.dy * location
        factory.point(segment.s.x + dx_location, segment.s.y + dy_location)
      end
    end
  end
end
