# == Schema Information
#
# Table name: gtfs_shapes
#
#  id              :integer          not null, primary key
#  shape_id        :string           not null
#  generated       :boolean          default(FALSE), not null
#  geometry        :geography({:srid not null, linestring, 4326
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#
# Indexes
#
#  index_gtfs_shapes_on_generated  (generated)
#  index_gtfs_shapes_on_geometry   (geometry) USING gist
#  index_gtfs_shapes_on_shape_id   (shape_id)
#  index_gtfs_shapes_unique        (feed_version_id,shape_id) UNIQUE
#

class GTFSShape < ActiveRecord::Base
  include GTFSEntity
  include HasAGeographicGeometry
  has_many :trips, class_name: 'GTFSTrip', foreign_key: 'shape_id'
  belongs_to :feed_version
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :shape_id, presence: true
  validates :generated, inclusion: { in: [true, false] }
  validates :geometry, presence: true
end
