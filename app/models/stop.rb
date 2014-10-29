# == Schema Information
#
# Table name: stops
#
#  id         :integer          not null, primary key
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#

class Stop < ActiveRecord::Base
  has_many :stop_identifiers, dependent: :destroy

  validates :onestop_id, presence: true, uniqueness: true # TODO: make this a more meaningful validation

  PER_PAGE = 50

  GEOFACTORY = RGeo::Geographic.spherical_factory(srid: 4326) # TODO: double check this
  set_rgeo_factory_for_column :geometry, GEOFACTORY.projection_factory
end
