RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  config.register(RGeo::Geographic.spherical_factory(srid: 4326))
end

# monkey patch modified from:
#https://github.com/rgeo/rgeo/issues/99
module RGeo
  module Cartesian
    module LineStringMethods
      def closest_point(target)
        nearest_locator(target).interpolate_point(factory)
      end

      def line_subset(start_index, stop_index)
        factory.line_string([_segments[start_index].s] + _segments[start_index..stop_index].map {|s| s.e})
      end

      def nearest_locator(target)
        locators(target).min_by(&:distance_from_segment)
      end

      def locators(point)
        _segments.collect { |segment| segment.locator(point) }
      end

      def before?(target)
        return _segments[0].tproj(target) < 0.0 ? true : false
      end

      def after?(target)
        return _segments[-1].tproj(target) > 1.0 ? true : false
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
        segment.tproj(target) * segment.length
      end

      def distance_from_segment
        return 0 if segment.contains_point?(target)
        dist_on_seg = distance_on_segment
        t_dist_from_departure = target_distance_from_departure
        return target.distance(segment.e) if dist_on_seg >= segment.length
        return target.distance(segment.s) if dist_on_seg <= 0
        diff = t_dist_from_departure - dist_on_seg
        # sometimes there can be a precision mismatch
        return 0 if (diff < 0 && diff.abs < 0.00001 )
        ::Math.sqrt( t_dist_from_departure ** 2 - dist_on_seg ** 2 ).round(5)
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
