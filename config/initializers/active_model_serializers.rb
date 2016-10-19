
class GeoJSONAdapter < ActiveModelSerializers::Adapter::Json
  def serializable_hash(options = nil)
    v = super
    v[:type] = 'FeatureCollection'
    v
    # options = serialization_options(options)
    # serialized_hash = { root => Attributes.new(serializer, instance_options).serializable_hash(options) }
    # serialized_hash[meta_key] = meta unless meta.blank?
    # serialized_hash[:type] = 'FeatureCollection'
    # serialized_hash
  end
end


# ActiveModel::Serializer.config.adapter = :json
