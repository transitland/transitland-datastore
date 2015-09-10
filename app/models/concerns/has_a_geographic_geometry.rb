module HasAGeographicGeometry
  extend ActiveSupport::Concern

  included do
    GEOFACTORY ||= RGeo::Geographic.spherical_factory(srid: 4326)

    scope :within_bbox, -> (bbox_coordinates) {
      if bbox_coordinates.is_a?(String)
        bbox_coordinates = bbox_coordinates.split(',').map(&:strip)
      end
      if bbox_coordinates.length != 4
        raise ArgumentError.new('must specify bbox coordinates')
      end
      where{st_intersects(geometry, st_makeenvelope(bbox_coordinates[0], bbox_coordinates[1], bbox_coordinates[2], bbox_coordinates[3], GEOFACTORY.srid))}
    }

    def self.convex_hull(entities, as: :geojson, projected: false)
      projected_geometries = entities.map { |e| e.geometry(as: :wkt, projected: true)}
      geometry_collection = RGeo::Geographic.simple_mercator_factory.projection_factory.collection(projected_geometries)
      convex_hull = geometry_collection.convex_hull

      if projected == false
        convex_hull = RGeo::Feature.cast(convex_hull,
          factory: RGeo::Geographic.spherical_factory(srid: 4326),
          project: true
        )
      end

      case as
      when :wkt
        return convex_hull
      when :geojson
        return RGeo::GeoJSON.encode(convex_hull).try(:symbolize_keys)
      end
    end
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

  def geometry(as: :geojson, projected: false)
    rgeo_geometry = self.send(:read_attribute, :geometry)

    if projected
      rgeo_geometry = RGeo::Feature.cast(
        rgeo_geometry,
        factory: RGeo::Geographic.simple_mercator_factory.projection_factory,
        project: true
      )
    end

    case as
    when :wkt
      return rgeo_geometry
     when :geojson
      return RGeo::GeoJSON.encode(rgeo_geometry).try(:symbolize_keys)
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
