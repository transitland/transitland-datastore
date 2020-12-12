module HasAGeographicGeometry
  extend ActiveSupport::Concern

  included do
    GEOFACTORY ||= RGeo::Geographic.spherical_factory(srid: 4326)
    def self.geofactory
      self.column_for_attribute(:geometry).cast_type.spatial_factory
    end

    validates :geometry, presence: true

    scope :geometry_within_bbox, -> (bbox_coordinates) {
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
      if (geometry_collection.size < 3)
        # 0.001 is in units of degrees Lat/Lon
        # Might be worthwhile to consider options
        # to turn this off or change magnitude.
        convex_hull = convex_hull.buffer(0.001)
      end

      if projected == false
        convex_hull = RGeo::Feature.cast(convex_hull,
          factory: GEOFACTORY,
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

  def geometry=(value)
    super(geometry_parse(value))
  end

  def geometry(**kwargs)
    geometry_encode(self.send(:read_attribute, :geometry), **kwargs)
  end

  def geometry_encode(rgeo_geometry, as: :geojson, projected: false)
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

  def geometry_parse(value)
    # Doesn't handle JSON strings
    if value.is_a?(Hash)
      # it's GeoJSON
      value = RGeo::GeoJSON.decode(JSON.dump(value), json_parser: :json).as_text
    end
    # it's WKT or a RGeo::Geographic feature
    value
  end

  def geometry_centroid
    centroid_from_geometry(geometry_for_centroid)
  end

  def geometry_for_centroid
    geometry(as: :wkt)
  end

  def geometry_bbox
    RGeo::Cartesian::BoundingBox.create_from_geometry(geometry(as: :wkt))
  end

  def centroid_from_geometry(geom)
    if geom.respond_to?(:lat) && geom.respond_to?(:lon)
      centroid = geom.dup
    else
      # RGeo centroid only works in Mercator
      geom_proj = RGeo::Feature.cast(
        geom,
        factory: RGeo::Geographic.simple_mercator_factory.projection_factory,
        project: true
      )
      if geom_proj.respond_to?(:centroid)
        # Project back
        centroid = RGeo::Feature.cast(
          geom_proj.centroid,
          factory: GEOFACTORY,
          project: true
        )
      else
        fail Exception.new("Cant create centroid: #{geom}")
      end
    end
    centroid
  end

  def validate_geometry

  end

  def validate_geometry_point
    self.geometry(as: :wkt).try(:geometry_type) == RGeo::Feature::Point
  end

  def validate_geometry_polygon
    self.geometry(as: :wkt).try(:geometry_type) == RGeo::Feature::Polygon
  end

end
