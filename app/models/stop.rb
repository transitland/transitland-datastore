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

  attr_accessor :served_by, :not_served_by
end

class Stop < StopBase
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [:served_by, :not_served_by]
  })
  def self.after_create_making_history(created_model, changeset)
    OperatorRouteStopRelationship.manage_multiple(
      stop: {
        served_by: created_model.served_by || [],
        not_served_by: created_model.not_served_by || [],
        model: created_model
      },
      changeset: changeset
    )
  end
  def before_update_making_history(changeset)
    OperatorRouteStopRelationship.manage_multiple(
      stop: {
        served_by: self.served_by || [],
        not_served_by: self.not_served_by || [],
        model: self
      },
      changeset: changeset
    )
  end
  def before_destroy_making_history(changeset, old_model)
    operators_serving_stop.each do |operator_serving_stop|
      operator_serving_stop.destroy_making_history(changeset)
    end
    return true
  end

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
