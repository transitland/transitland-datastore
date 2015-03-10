module Geojson
  extend ActiveSupport::Concern

  def self.from_entity_collection(entities)
    # TODO: paginate or serve as GeoJSON tiles, perhaps for consumption by
    # https://github.com/glenrobertson/leaflet-tilelayer-geojson
    factory = RGeo::GeoJSON::EntityFactory.instance
    features = entities.map do |entity|
      factory.feature(
        entity.geometry(as: :wkt),
        entity.onestop_id,
        {
          name: entity.name,
          created_at: entity.created_at,
          updated_at: entity.updated_at,
          tags: entity.tags,
          identifiers: entity.identifiers.map do |entity_identifier|
            {
              identifier: entity_identifier.identifier,
              tags: entity_identifier.tags,
              created_at: entity_identifier.created_at,
              updated_at: entity_identifier.updated_at
            }
          end
        }
      )
    end
    RGeo::GeoJSON.encode(factory.feature_collection(features))
  end
end
