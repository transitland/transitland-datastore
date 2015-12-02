# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id           :integer          not null, primary key
#  geometry     :geography({:srid geometry, 4326
#  tags         :hstore
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  route_id     :string
#  stop_pattern :string
#

class BaseRouteStopPattern < ActiveRecord::Base
  self.abstract_class = true

  include IsAnEntityImportedFromFeeds
end

class RouteStopPattern < BaseRouteStopPattern
  self.table_name_prefix = 'current_'

  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince


  def self.find_by_similarity(stop_pattern, shape_points)
    other = RouteStopPattern::GEOFACTORY.line_string(
      shape_points.map { |lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat) }
    )
    #where { st_equals(other.to_s) }.last
    where(geometry: other)
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(trip, shape_points)
    rsp = RouteStopPattern.new(
      geometry: RouteStopPattern::GEOFACTORY.line_string(
        shape_points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
      )
    )
    rsp.tags ||= {}
    rsp.tags[:shape_id] = trip.shape_id
    rsp
  end
end

class OldRouteStopPattern < BaseRouteStopPattern
  include OldTrackedByChangeset
  include HasAGeographicGeometry
end
