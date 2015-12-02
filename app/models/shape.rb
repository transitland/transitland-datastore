# == Schema Information
#
# Table name: current_shapes
#
#  id         :integer          not null, primary key
#  geometry   :geography({:srid geometry, 4326
#  tags       :hstore
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class BaseShape < ActiveRecord::Base
  self.abstract_class = true

  include IsAnEntityImportedFromFeeds
end

class Shape < BaseShape
  self.table_name_prefix = 'current_'

  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince


  def self.find_by_similarity(shape_points)
    other = Shape::GEOFACTORY.line_string(
      shape_points.map { |lon, lat| Shape::GEOFACTORY.point(lon, lat) }
    )
    #where { st_equals(other.to_s) }.last
    where(geometry: other)
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(shape_id, shape_points)
    shape = Shape.new(
      geometry: Shape::GEOFACTORY.line_string(
        shape_points.map {|lon, lat| Shape::GEOFACTORY.point(lon, lat)}
      )
    )
    shape.tags ||= {}
    shape.tags[:shape_id] = shape_id
    shape
  end
end

class OldShape < BaseShape
  include OldTrackedByChangeset
  include HasAGeographicGeometry
end
