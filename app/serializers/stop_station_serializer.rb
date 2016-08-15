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
#  identifiers                        :string           default([]), is an Array
#  timezone                           :string
#  last_conflated_at                  :datetime
#  type                               :string
#  parent_stop_id                     :integer
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index      (created_or_updated_in_changeset_id)
#  index_current_stops_on_geometry        (geometry)
#  index_current_stops_on_identifiers     (identifiers)
#  index_current_stops_on_onestop_id      (onestop_id)
#  index_current_stops_on_parent_stop_id  (parent_stop_id)
#  index_current_stops_on_tags            (tags)
#  index_current_stops_on_updated_at      (updated_at)
#

class StopStationSerializer < CurrentEntitySerializer
  # Platform serializer
  class StopPlatformSerializer < CurrentEntitySerializer
    attributes :onestop_id,
               :geometry,
               :name,
               :tags,
               :served_by_vehicle_types,
               :timezone,
               :created_at,
               :updated_at,
               :last_conflated_at
     has_many :operators_serving_stop
     has_many :routes_serving_stop
     has_many :stop_transfers
  end
  # Egress serializer
  class StopEgressSerializer < CurrentEntitySerializer
    attributes :onestop_id,
               :geometry,
               :name,
               :tags,
               :timezone,
               :osm_way_id,
               :created_at,
               :updated_at
               :last_conflated_at
  end

  # Create phantom platforms / egresses
  def stop_egresses
    object.stop_egresses.presence || [StopEgress.new(
      onestop_id: "#{object.onestop_id}>",
      geometry: object.geometry,
      name: object.name,
      timezone: object.timezone,
      last_conflated_at: object.last_conflated_at,
      osm_way_id: object.osm_way_id
    )]
  end

  def stop_platforms
    object.stop_platforms.presence || [StopPlatform.new(
      onestop_id: "#{object.onestop_id}<",
      geometry: object.geometry,
      name: object.name,
      timezone: object.timezone,
      operators_serving_stop: object.operators_serving_stop,
      routes_serving_stop: object.routes_serving_stop,
      tags: {}
    )]
  end

  # Aggregate operators_serving_stop
  def operators_serving_stop_and_platforms
    # stop_platforms, operators_serving_stop loaded through .includes
    result = object.operators_serving_stop
    object.stop_platforms.each { |sp| result |= sp.operators_serving_stop }
    result.uniq { |osr| osr.operator }
  end

  # Aggregate routes_serving_stop
  def routes_serving_stop_and_platforms
    # stop_platforms, routes_serving_stop loaded through .includes
    result = object.routes_serving_stop
    object.stop_platforms.each { |sp| result |= sp.routes_serving_stop }
    result.uniq { |osr| osr.route }
  end

  # Attributes
  attributes :onestop_id,
             :geometry,
             :name,
             :tags,
             :timezone,
             :vehicle_types_serving_stop_and_platforms,
             :created_at,
             :updated_at

  # Relations
  has_many :stop_platforms, serializer: StopPlatformSerializer
  has_many :stop_egresses, serializer: StopEgressSerializer
  has_many :stop_transfers
  has_many :operators_serving_stop_and_platforms
  has_many :routes_serving_stop_and_platforms
end
