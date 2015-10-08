module Geojson
  extend ActiveSupport::Concern

  def self.from_entity_collection(entities)
    # TODO: paginate or serve as GeoJSON tiles, perhaps for consumption by
    # https://github.com/glenrobertson/leaflet-tilelayer-geojson
    factory = RGeo::GeoJSON::EntityFactory.instance
    features = entities.map do |entity|
      next if entity.geometry.blank?
      properties = {
        created_at: entity.created_at,
        updated_at: entity.updated_at,
        tags: entity.tags
      }
      (properties[:name] = entity.name) if entity.try(:name)
      (properties[:identifiers] = entity.identifiers) if entity.try(:identifiers)
      factory.feature(
        entity.geometry(as: :wkt),
        entity.onestop_id,
        properties
      )
    end
    RGeo::GeoJSON.encode(factory.feature_collection(features))
  end
end
