# == Schema Information
#
# Table name: current_stops
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  name                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#
# Indexes
#
#  #c_stops_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  index_current_stops_on_onestop_id  (onestop_id)
#

class BaseStop < ActiveRecord::Base
  self.abstract_class = true

  PER_PAGE = 50

  attr_accessor :served_by, :not_served_by
end

class Stop < BaseStop
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  include CanBeSerializedToCsv
  def self.csv_column_names
    [
      'Onestop ID',
      'Name',
      'Operators serving stop (names)',
      'Operators serving stop (Onestop IDs)',
      'Latitude (centroid)',
      'Longitude (centroid)'
    ]
  end
  def csv_row_values
    [
      onestop_id,
      name,
      operators_serving_stop.map {|oss| oss.operator.name }.join(', '),
      operators_serving_stop.map {|oss| oss.operator.onestop_id }.join(', '),
      geometry_centroid[:lat],
      geometry_centroid[:lon]
    ]
  end

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
      operator_serving_stop.destroy_making_history(changeset: changeset)
    end
    routes_serving_stop.each do |route_serving_stop|
      route_serving_stop.destroy_making_history(changeset: changeset)
    end
    return true
  end

  has_many :operators_serving_stop
  has_many :operators, through: :operators_serving_stop

  has_many :routes_serving_stop
  has_many :routes, through: :routes_serving_stop

  scope :served_by, -> (onestop_ids_and_models) {
    operators = []
    routes = []
    onestop_ids_and_models.each do |onestop_id_or_model|
      case onestop_id_or_model
      when Operator
        operators << onestop_id_or_model
      when Route
        routes << onestop_id_or_model
      when String
        model = OnestopIdService.find!(onestop_id_or_model)
        case model
        when Route then routes << model
        when Operator then operators << model
        else ArgumentError.new('only accepts Operator or Route models')
        end
      else
        raise ArgumentError.new('must provide an Operator model or a Onestop ID')
      end
    end
    if operators.length > 0 && routes.length > 0
      joins{
        operators_serving_stop.operator
      }.joins{
        routes_serving_stop.route
      }.where{
        (operators_serving_stop.operator_id >> operators.map(&:id)) |
        (routes_serving_stop.route_id >> routes.map(&:id))
      }.uniq(:stop)
    elsif operators.length > 0
      joins{operators_serving_stop.operator}.where{operators_serving_stop.operator_id >> operators.map(&:id)}.uniq(:stop)
    elsif routes.length > 0
      joins{routes_serving_stop.route}.where{routes_serving_stop.route_id >> routes.map(&:id)}.uniq(:stop)
    else
      raise ArgumentError.new('must provide at least one Operator or Route')
    end
  }
  scope :served_by_route, -> (route) {
    joins{routes_serving_stop.route}.where{routes_serving_stop.route_id == route.id}
  }
  scope :served_by_operator, -> (operator) {
    joins{operators_serving_stop.operator}.where{operators_serving_stop.operator_id == operator.id}
  }

  before_save :clean_attributes

  private

  def clean_attributes
    self.name.strip! if self.name.present?
  end
end

class OldStop < BaseStop
  include OldTrackedByChangeset
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry

  has_many :old_operators_serving_stop, as: :stop
  has_many :operators, through: :old_operators_serving_stop, source_type: 'Stop'

  has_many :old_routes_serving_stop, as: :stop
  has_many :routes, through: :old_routes_serving_stop, source_type: 'Stop'
end
