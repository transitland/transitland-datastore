# == Schema Information
#
# Table name: operators
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  tags       :hstore
#  created_at :datetime
#  updated_at :datetime
#  onestop_id :string(255)
#  geometry   :spatial          geometry, 4326
#
# Indexes
#
#  index_operators_on_onestop_id  (onestop_id) UNIQUE
#

class Operator < ActiveRecord::Base
  include HasAOnestopId
  include IsAnEntityWithIdentifiers

  has_many :operators_serving_stop, dependent: :destroy
  has_many :stops, through: :operators_serving_stop

  PER_PAGE = 50

  GEOFACTORY = RGeo::Geographic.simple_mercator_factory #(srid: 4326) # TODO: double check this
  set_rgeo_factory_for_column :geometry, GEOFACTORY

  validate :name, presence: true
end
