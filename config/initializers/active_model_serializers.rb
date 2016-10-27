class GeoJSONAdapter < ActiveModelSerializers::Adapter::Json
  def serializable_hash(options = nil)
    v = super
    v[:type] = 'FeatureCollection'
    v
  end
end

# ActiveModel::Serializer.config.adapter = :json
