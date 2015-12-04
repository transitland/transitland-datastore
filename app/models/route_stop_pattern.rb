# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id                                 :integer          not null, primary key
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  route_id                           :string
#  stop_pattern                       :string           default([]), is an Array
#  version                            :integer
#  created_or_updated_in_changeset_id :integer
#

# TODO: uniqueness,
# relationship to route and ssp,
# unique "friendly" id based on stop seq and geom
# calc distances (in separate import level)
# required fields

class BaseRouteStopPattern < ActiveRecord::Base
  self.abstract_class = true

  include IsAnEntityImportedFromFeeds
end

class RouteStopPattern < BaseRouteStopPattern
  self.table_name_prefix = 'current_'

  #include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince

  def self.find_equivalent(stop_pattern, shape_points)
    other = RouteStopPattern::GEOFACTORY.line_string(
      shape_points.map { |lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat) }
    )
    where(geometry: other, stop_pattern: stop_pattern)
  end

  # Tracked by changeset
  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :relationship,
    virtual_attributes: [
      :imported_from_feed
    ]
  })
  # borrowed from schedule_stop_pair.rb
  def self.find_by_attributes(attrs = {})
    if attrs[:id].present?
      find(attrs[:id])
    end
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(trip, stop_pattern, shape_points)
    rsp = RouteStopPattern.new(
      route_id: trip.route_id,
      stop_pattern: stop_pattern,
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
