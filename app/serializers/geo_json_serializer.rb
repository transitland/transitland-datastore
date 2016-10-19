class GeoJSONSerializer < ApplicationSerializer
  attributes :geometry, :properties, :type

  def properties
    ActiveModel::Serializer
      .serializer_for(object)
      .new(object)
      .as_json
      .except(:geometry)
  end

  def type
    'Feature'
  end

  def geometry
    object.try(:geometry)
  end
end
