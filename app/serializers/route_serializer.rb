# == Schema Information
#
# Table name: current_routes
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  name                               :string
#  tags                               :hstore
#  operator_id                        :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  geometry                           :geography({:srid geometry, 4326
#  vehicle_type                       :integer
#  color                              :string
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_accessible              :string           default("unknown")
#  bikes_allowed                      :string           default("unknown")
#
# Indexes
#
#  c_route_cu_in_changeset                        (created_or_updated_in_changeset_id)
#  index_current_routes_on_bikes_allowed          (bikes_allowed)
#  index_current_routes_on_geometry               (geometry) USING gist
#  index_current_routes_on_onestop_id             (onestop_id) UNIQUE
#  index_current_routes_on_operator_id            (operator_id)
#  index_current_routes_on_tags                   (tags)
#  index_current_routes_on_updated_at             (updated_at)
#  index_current_routes_on_vehicle_type           (vehicle_type)
#  index_current_routes_on_wheelchair_accessible  (wheelchair_accessible)
#

class RouteSerializer < CurrentEntitySerializer
  attributes :name,
             :vehicle_type,
             :color,
             :stops_served_by_route,
             :operated_by_onestop_id,
             :operated_by_name,
             :wheelchair_accessible,
             :bikes_allowed,
             :route_stop_patterns_by_onestop_id

  attribute :headways, if: :include_headways?

  def operated_by_onestop_id
    object.operator.try(:onestop_id)
  end

  def operated_by_name
    object.operator.try(:name)
  end

  def stops_served_by_route
    object.stops.map { |stop| { stop_onestop_id: stop.onestop_id, stop_name: stop.name } }
  end

  def route_stop_patterns_by_onestop_id
    object.route_stop_patterns.map(&:onestop_id)
  end

  def include_headways?
    !scope[:headways].nil?
  end

  def headways
    h = scope[:headways_data] || {}
    h = h.select { |k,v| k[0] == object.onestop_id }
    h = h.map { |k,v| [k.join(':'), v] }.to_h
    h
  end
end
