RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
  config.register(RGeo::Geographic.spherical_factory(srid: 4326))
end
