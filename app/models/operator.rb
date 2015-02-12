# == Schema Information
#
# Table name: operators
#
#  id                                 :integer          not null, primary key
#  name                               :string(255)
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  onestop_id                         :string(255)
#  geometry                           :spatial          geometry, 4326
#  created_or_updated_in_changeset_id :integer
#  destroyed_in_changeset_id          :integer
#  version                            :integer
#  current                            :boolean
#
# Indexes
#
#  index_operators_on_current          (current)
#  index_operators_on_onestop_id       (onestop_id) UNIQUE
#  operators_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  operators_d_in_changeset_id_index   (destroyed_in_changeset_id)
#

class Operator < ActiveRecord::Base
  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include TrackedByChangeset

  has_many :operators_serving_stop, dependent: :destroy
  has_many :stops, through: :operators_serving_stop

  PER_PAGE = 50

  GEOFACTORY = RGeo::Geographic.simple_mercator_factory #(srid: 4326) # TODO: double check this
  set_rgeo_factory_for_column :geometry, GEOFACTORY

  validate :name, presence: true
end
