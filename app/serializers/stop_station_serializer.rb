class StopStationSerializer < CurrentEntitySerializer
  # Platform serializer
  class StopPlatformSerializer < CurrentEntitySerializer
    attributes :name,
               :served_by_vehicle_types,
               :timezone,
               :wheelchair_boarding,
               :generated,
               :last_conflated_at
     has_many :operators_serving_stop
     has_many :routes_serving_stop
     has_many :stop_transfers

     def generated
       !object.persisted?
     end
  end
  # Egress serializer
  class StopEgressSerializer < CurrentEntitySerializer
    attributes :name,
               :timezone,
               :osm_way_id,
               :wheelchair_boarding,
               :generated,
               :directionality,
               :last_conflated_at

     def generated
       !object.persisted?
     end
  end

  # Create phantom platforms / egresses
  def stop_egresses
    object.stop_egresses.presence || [StopEgress.new(
      onestop_id: "#{object.onestop_id}>",
      geometry: object.geometry,
      name: object.name,
      timezone: object.timezone,
      last_conflated_at: object.last_conflated_at,
      osm_way_id: object.osm_way_id,
      directionality: nil
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
      tags: {},
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
  attributes :name,
             :timezone,
             :vehicle_types_serving_stop_and_platforms,
             :wheelchair_boarding

  # Relations
  has_many :stop_platforms, serializer: StopPlatformSerializer
  has_many :stop_egresses, serializer: StopEgressSerializer
  has_many :stop_transfers
  has_many :operators_serving_stop_and_platforms
  has_many :routes_serving_stop_and_platforms
end
