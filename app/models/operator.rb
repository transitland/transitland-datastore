# == Schema Information
#
# Table name: current_operators
#
#  id                                 :integer          not null, primary key
#  name                               :string(255)
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  onestop_id                         :string(255)
#  geometry                           :spatial          geometry, 4326
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#
# Indexes
#
#  #c_operators_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  index_current_operators_on_onestop_id  (onestop_id) UNIQUE
#

class BaseOperator < ActiveRecord::Base
  self.abstract_class = true

  PER_PAGE = 50
end

class Operator < BaseOperator
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include CurrentTrackedByChangeset
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  has_many :operators_serving_stop
  has_many :stops, through: :operators_serving_stop

  validate :name, presence: true
end

class OldOperator < BaseOperator
  include OldTrackedByChangeset
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  has_many :operators_serving_stop
  # has_many :operators, through: :operators_serving_stop
end
