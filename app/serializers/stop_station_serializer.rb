class StopStationSerializer < CurrentEntitySerializer
  # Platform serializer
  class StopPlatformSerializer < CurrentEntitySerializer
    attributes :name,
               :timezone,
               :wheelchair_boarding,
               :served_by_vehicle_types,
               :operators_serving_stop, # use attr, not has_many; see below
               :routes_serving_stop,    # ..
               :stop_transfers,         # ..
               :generated

    attribute :geometry_reversegeo, if: :include_geometry?
    attribute :geometry_centroid, if: :include_geometry?

    def operators_serving_stop
      # Force through serializer
      object.operators_serving_stop.map { |i| OperatorServingStopSerializer.new(i) }
    end

    def routes_serving_stop
      object.routes_serving_stop.map { |i| RouteServingStopSerializer.new(i) }
    end

    def stop_transfers
      object.stop_transfers.map { |i| StopTransferSerializer.new(i) }
    end

    def generated
      !object.persisted?
    end

    def geometry_centroid
      RGeo::GeoJSON.encode(object.geometry_centroid)
    end
  end

  # Egress serializer
  class StopEgressSerializer < CurrentEntitySerializer
    attributes :name,
               :timezone,
               :wheelchair_boarding,
               :osm_way_id,
               :last_conflated_at,
               :directionality,
               :generated

    attribute :geometry_reversegeo, if: :include_geometry?
    attribute :geometry_centroid, if: :include_geometry?

    def generated
      !object.persisted?
    end

    def geometry_centroid
      RGeo::GeoJSON.encode(object.geometry_centroid)
    end
  end

  def stop_platforms
    s = object.stop_platforms.presence || []
    if scope[:generated]
      s << StopPlatform.new(
        onestop_id: "#{object.onestop_id}<",
        geometry: object.geometry,
        name: object.name,
        timezone: object.timezone,
        wheelchair_boarding: object.wheelchair_boarding,
        operators_serving_stop: object.operators_serving_stop,
        routes_serving_stop: object.routes_serving_stop,
        tags: {},
      )
    end
    s
  end

  # Create phantom platforms / egresses
  def stop_egresses
    s = object.stop_egresses.presence || []
    if s.empty? && scope[:generated]
      s << StopEgress.new(
        onestop_id: "#{object.onestop_id}>",
        geometry: object.geometry,
        name: object.name,
        timezone: object.timezone,
        wheelchair_boarding: object.wheelchair_boarding,
        last_conflated_at: object.last_conflated_at,
        osm_way_id: object.osm_way_id,
        directionality: nil
      )
    end
    s
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
             :wheelchair_boarding,
             :osm_way_id,
             :last_conflated_at,
             :vehicle_types_serving_stop_and_platforms

  attribute :geometry_reversegeo, if: :include_geometry?
  attribute :geometry_centroid, if: :include_geometry?

  # Relations
  has_many :stop_platforms, serializer: StopPlatformSerializer
  has_many :stop_egresses, serializer: StopEgressSerializer
  has_many :stop_transfers
  has_many :operators_serving_stop_and_platforms
  has_many :routes_serving_stop_and_platforms

  #

  def geometry_centroid
    RGeo::GeoJSON.encode(object.geometry_centroid)
  end
end
