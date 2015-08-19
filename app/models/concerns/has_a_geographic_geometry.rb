module HasAGeographicGeometry
  extend ActiveSupport::Concern

  included do
    GEOFACTORY ||= RGeo::Geographic.spherical_factory(srid: 4326)
  end

  def geometry=(incoming_geometry)
    case incoming_geometry
    when Hash
      # it's GeoJSON
      geojson_as_string = JSON.dump(incoming_geometry)
      parsed_geojson = RGeo::GeoJSON.decode(geojson_as_string, json_parser: :json)
      self.send(:write_attribute, :geometry, parsed_geojson.as_text)
    when String
      # it's WKT
      self.send(:write_attribute, :geometry, incoming_geometry)
    end
  end

  def geometry(as: :geojson)
    case as
    when :wkt
      return self.send(:read_attribute, :geometry)
     when :geojson
      return RGeo::GeoJSON.encode(self.send(:read_attribute, :geometry)).try(:symbolize_keys)
    end
  end

  def geometry_centroid
    wkt = geometry(as: :wkt)
    if wkt.respond_to?(:lat) && wkt.respond_to?(:lon)
      lat = wkt.lat
      lon = wkt.lon
    else
      projected_geometry = RGeo::Feature.cast(wkt,
        factory: RGeo::Geographic.simple_mercator_factory,
        project: true
      )
      centroid = projected_geometry.centroid
      lat = centroid.lat
      lon = centroid.lon
    end
    {
      lon: lon,
      lat: lat
    }
  end
end
