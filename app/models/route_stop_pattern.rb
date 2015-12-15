# == Schema Information
#
# Table name: current_route_stop_patterns
#
#  id                                 :integer          not null, primary key
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  stop_pattern                       :string           default([]), is an Array
#  version                            :integer
#  created_or_updated_in_changeset_id :integer
#  onestop_id                         :string
#  route_id                           :integer
#  route_type                         :string
#  is_generated                       :boolean          default(FALSE)
#  is_modified                        :boolean          default(FALSE)
#  is_only_stop_points                :boolean          default(FALSE)
#  trips                              :string           default([]), is an Array
#  identifiers                        :string           default([]), is an Array
#
# Indexes
#
#  index_current_route_stop_patterns_on_route_type_and_route_id  (route_type,route_id)
#

class BaseRouteStopPattern < ActiveRecord::Base
  self.abstract_class = true

  include IsAnEntityImportedFromFeeds

  attr_accessor :traversed_by
end

class RouteStopPattern < BaseRouteStopPattern
  self.table_name_prefix = 'current_'

  belongs_to :route #route_type for polymorphic association?
  validates :geometry, :stop_pattern, presence: true

  #include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince

  # Tracked by changeset
  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :imported_from_feed,
      :identified_by,
      :not_identified_by,
      :traversed_by
    ]
  })
  class << RouteStopPattern
    alias_method :existing_before_create_making_history, :before_create_making_history
  end
  def self.before_create_making_history(new_model, changeset)
    route = Route.find_by_onestop_id!(new_model.traversed_by)
    new_model.route = route
    self.existing_before_create_making_history(new_model, changeset)
  end
  # borrowed from schedule_stop_pair.rb
  def self.find_by_attributes(attrs = {})
    if attrs[:id].present?
      find(attrs[:id])
    end
  end

  scope :route_onestop_id, -> (route_onestop_id) {
    where(route_id: Route.select(:id).where(onestop_id: route_onestop_id))
  }

  scope :unique_components_by_route_onestop_id, -> (rt_onestop_id, component_num) {
    route_onestop_id(rt_onestop_id).pluck(:onestop_id)
    .map {|f_id| f_id.split("#")[component_num]}.uniq
  }

  def self.generate_component_id(route_onestop_id, feed_onestop_ids, component)
    # S for stop_pattern, G for geometry
    component_num_hash = {'S' => 1, 'G' => 2}
    component_count = unique_components_by_route_onestop_id(route_onestop_id, component_num_hash[component]).size
    component_count += feed_onestop_ids.select {|f_id| f_id.split("#")[0] == route_onestop_id}
      .map {|f_id| f_id.split("#")[component_num_hash[component]]}.uniq.size
    "#{component}#{component_count + 1}"
  end

  def self.new_geometry(points)
    RouteStopPattern::GEOFACTORY.line_string(
      points.map {|lon, lat| RouteStopPattern::GEOFACTORY.point(lon, lat)}
    )
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(trip, stop_pattern, shape_points)
    rsp = RouteStopPattern.new(
      stop_pattern: stop_pattern,
      geometry: self.new_geometry(shape_points)
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
