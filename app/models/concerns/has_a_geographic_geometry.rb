module HasAGeographicGeometry
  extend ActiveSupport::Concern

  included do
    GEOFACTORY = RGeo::Geographic.simple_mercator_factory #(srid: 4326) # TODO: double check this
    set_rgeo_factory_for_column :geometry, GEOFACTORY
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
    elsif wkt.respond_to?(:centroid)
      # TODO: fix this
      lat = nil
      lon = nil
      # centroid = wkt.centroid
      # lat = centroid.lat
      # lon = centroid.lon
    else
      lat = nil
      lon = nil
    end
    {
      lon: lon,
      lat: lat
    }
  end
end
