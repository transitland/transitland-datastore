# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string(255)
#  geometry                           :spatial          geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string(255)
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  index_current_stops_on_onestop_id  (onestop_id)
#

class StopBase < ActiveRecord::Base
  self.abstract_class = true

  PER_PAGE = 50
end

class Stop < StopBase
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include CurrentTrackedByChangeset
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  has_many :operators_serving_stop
  has_many :operators, through: :operators_serving_stop

  before_save :clean_attributes

  private

  def clean_attributes
    self.name.strip! if self.name.present?
  end
end

class OldStop < StopBase
  include OldTrackedByChangeset
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  has_many :operators_serving_stop
  # has_many :operators, through: :operators_serving_stop
end
