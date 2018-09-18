# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#  osm_way_id                         :integer
#  edited_attributes                  :string           default([]), is an Array
#  wheelchair_boarding                :boolean
#  directionality                     :integer
#  geometry_reversegeo                :geography({:srid point, 4326
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index           (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry             (geometry) USING gist
#  index_current_stops_on_geometry_reversegeo  (geometry_reversegeo) USING gist
#  index_current_stops_on_onestop_id           (onestop_id) UNIQUE
#  index_current_stops_on_parent_stop_id       (parent_stop_id)
#  index_current_stops_on_tags                 (tags)
#  index_current_stops_on_updated_at           (updated_at)
#  index_current_stops_on_wheelchair_boarding  (wheelchair_boarding)
#

class StopSerializer < CurrentEntitySerializer
  attributes :name,
             :timezone,
             :osm_way_id,
             :served_by_vehicle_types,
             :parent_stop_onestop_id,
             :wheelchair_boarding

  attribute :geometry_reversegeo, if: :include_geometry?
  attribute :geometry_centroid, if: :include_geometry?
  attribute :headways, if: :include_headways?

  has_many :operators_serving_stop
  has_many :routes_serving_stop

  def parent_stop_onestop_id
    object.parent_stop.try(:onestop_id)
  end

  def geometry_centroid
    RGeo::GeoJSON.encode(object.geometry_centroid)
  end

  def include_headways?
    !scope[:headways].nil?
  end

  def headways
    h = scope[:headways_data] || {}
    h = h.select { |k,v| k[0] == object.onestop_id }
    h = h.map { |k,v| [k.join(':'), v] }.to_h
    h[:min] = h.values.min
    h[:max] = h.values.max
    h
  end
end
