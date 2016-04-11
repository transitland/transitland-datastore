module Geojson
  extend ActiveSupport::Concern

  FACTORY = RGeo::GeoJSON::EntityFactory.instance

  def self.from_entity_collection(entities, &block)
    # TODO: paginate or serve as GeoJSON tiles, perhaps for consumption by
    # https://github.com/glenrobertson/leaflet-tilelayer-geojson
    features = entities.map do |entity|
      entity_to_feature(entity, &block)
    end
    RGeo::GeoJSON.encode(FACTORY.feature_collection(features))
  end

  def self.from_entity(entity, &block)
    feature = entity_to_feature(entity, &block)
    RGeo::GeoJSON.encode(feature)
  end

  private

  def self.entity_to_feature(entity, &block)
    return if entity.geometry.blank?
    properties = {
      created_at: entity.created_at,
      updated_at: entity.updated_at
    }
    (properties[:onestop_id] = entity.onestop_id) if entity.try(:onestop_id)
    (properties[:tags] = entity.tags) if entity.try(:tags)
    (properties[:name] = entity.name) if entity.try(:name)
    (properties[:identifiers] = entity.identifiers) if entity.try(:identifiers)
    block.call(properties, entity) if block_given?
    FACTORY.feature(
      entity.geometry(as: :wkt),
      entity.onestop_id,
      properties
    )
  end
end
