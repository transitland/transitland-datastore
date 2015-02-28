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

  attr_accessor :serves, :does_not_serve
end

class Operator < BaseOperator
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [:serves, :does_not_serve]
  })
  def self.after_create_making_history(created_model, changeset)
    OperatorRouteStopRelationship.manage_multiple(
      operator: {
        serves: created_model.serves || [],
        does_not_serve: created_model.does_not_serve || [],
        model: created_model
      },
      changeset: changeset
    )
  end
  def before_update_making_history(changeset)
    OperatorRouteStopRelationship.manage_multiple(
      operator: {
        serves: self.serves || [],
        does_not_serve: self.does_not_serve || [],
        model: self
      },
      changeset: changeset
    )
  end
  def before_destroy_making_history(changeset, old_model)
    operators_serving_stop.each do |operator_serving_stop|
      operator_serving_stop.destroy_making_history(changeset: changeset)
    end
    routes_serving_stop.each do |route_serving_stop|
      route_serving_stop.destroy_making_history(changeset: changeset)
    end
    return true
  end

  has_many :operators_serving_stop
  has_many :stops, through: :operators_serving_stop

  has_many :routes
  has_many :routes_serving_stop, through: :routes

  validate :name, presence: true
end

class OldOperator < BaseOperator
  include OldTrackedByChangeset
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  has_many :old_operators_serving_stop, as: :operator
  has_many :operators, through: :operators_serving_stop

  has_many :routes, as: :operator
end
