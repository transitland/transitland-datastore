module HasAGeographicGeometry
  extend ActiveSupport::Concern

  def geometry=(new_geometry)
    @geometry = new_geometry
  end

  def geometry(as: :wkt)
    if as == :wkt
      return @geometry
    elsif as == :geojson
      return @geometry # TODO
    end
  end
end
