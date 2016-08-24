# == Schema Information
#
# Table name: current_routes
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  name                               :string
#  tags                               :hstore
#  operator_id                        :integer
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  geometry                           :geography({:srid geometry, 4326
#  identifiers                        :string           default([]), is an Array
#  vehicle_type                       :integer
#  color                              :string
#
# Indexes
#
#  c_route_cu_in_changeset               (created_or_updated_in_changeset_id)
#  index_current_routes_on_geometry      (geometry)
#  index_current_routes_on_identifiers   (identifiers)
#  index_current_routes_on_operator_id   (operator_id)
#  index_current_routes_on_tags          (tags)
#  index_current_routes_on_updated_at    (updated_at)
#  index_current_routes_on_vehicle_type  (vehicle_type)
#

class BaseRoute < ActiveRecord::Base
  self.abstract_class = true
  attr_accessor :serves, :does_not_serve, :operated_by

  extend Enumerize
  enumerize :vehicle_type,
            in: GTFS::Route::VEHICLE_TYPES.invert.inject({}) {
              |hash, (k,v)| hash[k.to_s.parameterize('_').to_sym] = v.to_s.to_i if k.present?; hash
            }
end

class Route < BaseRoute
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince
  include IsAnEntityImportedFromFeeds

  include CanBeSerializedToCsv
  def self.csv_column_names
    [
      'Onestop ID',
      'Name',
      'Operated by (name)',
      'Operated by (Onestop ID)'
    ]
  end

  def csv_row_values
    [
      onestop_id,
      name,
      operator.try(:name),
      operator.try(:onestop_id)
    ]
  end

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :serves,
      :does_not_serve,
      :operated_by,
      :identified_by,
      :not_identified_by
    ],
    protected_attributes: [
      :identifiers
    ]
  })

  # FIXME: this is a temporary fix to run both the following `before_create_making_history` changeset
  # callback as well as the callback of the same name that is included from IsAnEntityWithIdentifiers
  class << Route
    alias_method :existing_before_create_making_history, :before_create_making_history
  end
  def self.before_create_making_history(new_model, changeset)
    operator = Operator.find_by_onestop_id!(new_model.operated_by)
    new_model.operator = operator
    self.existing_before_create_making_history(new_model, changeset)
  end
  def after_create_making_history(changeset)
    OperatorRouteStopRelationship.manage_multiple(
      route: {
        serves: self.serves || [],
        does_not_serve: self.does_not_serve || [],
        model: self
      },
      changeset: changeset
    )
  end
  def before_update_making_history(changeset)
    if self.operated_by.present?
      operator = Operator.find_by_onestop_id!(self.operated_by)
      self.operator = operator
    end
    OperatorRouteStopRelationship.manage_multiple(
      route: {
        serves: self.serves || [],
        does_not_serve: self.does_not_serve || [],
        model: self
      },
      changeset: changeset
    )
    super(changeset)
  end
  def before_destroy_making_history(changeset, old_model)
    routes_serving_stop.each do |route_serving_stop|
      route_serving_stop.destroy_making_history(changeset: changeset)
    end
    route_stop_patterns.each do |route_stop_pattern|
      route_stop_pattern.destroy_making_history(changeset: changeset)
    end
    return true
  end

  has_many :routes_serving_stop
  has_many :stops, through: :routes_serving_stop
  has_many :schedule_stop_pairs
  has_many :route_stop_patterns
  belongs_to :operator

  validates :name, presence: true
  validate :validate_color_attr

  def validate_color_attr
    errors.add(:color, "invalid color") unless Route.color_valid?(self.color)
  end

  def self.color_valid?(color)
    return true if color.to_s.empty?
    !!(/^[0-9A-F]{6}$/.match(color))
  end

  def self.color_from_gtfs(route_color)
    route_color.upcase if route_color && Route.color_valid?(route_color.upcase)
  end

  scope :where_serves, -> (onestop_ids_and_models) {
    # Accept one or more Stop models / onestop_ids.
    onestop_ids_and_models = Array.wrap(onestop_ids_and_models)
    stops, onestop_ids = onestop_ids_and_models.partition { |i| i.is_a?(Stop) }
    stops += Stop.find_by_onestop_ids!(onestop_ids)
    joins{routes_serving_stop.route}.where{routes_serving_stop.stop_id.in(stops.map(&:id))}.uniq
  }

  scope :operated_by, -> (model_or_onestop_id) {
    if model_or_onestop_id.is_a?(Operator)
      where(operator: model_or_onestop_id)
    elsif model_or_onestop_id.is_a?(String)
      operator = Operator.find_by_onestop_id!(model_or_onestop_id)
      where(operator: operator)
    else
      raise ArgumentError.new('must provide an Operator model or a Onestop ID')
    end
  }

  scope :traverses, -> (route_stop_pattern_onestop_id) {
    where(id: RouteStopPattern.select(:route_id).where(onestop_id: route_stop_pattern_onestop_id))
  }

  scope :stop_within_bbox, -> (bbox) {
    where(id: RouteServingStop.select(:route_id).where(stop: Stop.geometry_within_bbox(bbox)))
  }

  scope :where_vehicle_type, -> (vehicle_types) {
    # Titleize input: high_speed_rail_service -> High Speed Rail Service
    # Then convert back to GTFS spec vehicle_type integer.
    vehicle_types = Array.wrap(vehicle_types).map { |vt| GTFS::Route.match_vehicle_type(vt.to_s.titleize).to_s.to_i }
    where(vehicle_type: vehicle_types)
  }

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(entity, attrs={})
    # GTFS Constructor
    coordinates = Stop::GEOFACTORY.collection(
      entity.stops.map { |stop| Stop::GEOFACTORY.point(*stop.coordinates) }
    )
    geohash = GeohashHelpers.fit(coordinates)
    name = [entity.route_short_name, entity.route_long_name, entity.id, "unknown"]
      .select(&:present?)
      .first
    onestop_id = OnestopId.handler_by_model(self).new(
      geohash: geohash,
      name: name
    )
    route = Route.new(
      name: name,
      onestop_id: onestop_id.to_s,
      vehicle_type: entity.route_type.to_i
    )
    route.color = Route.color_from_gtfs(entity.route_color)
    # Copy over GTFS attributes to tags
    route.tags ||= {}
    route.tags[:route_long_name] = entity.route_long_name
    route.tags[:route_desc] = entity.route_desc
    route.tags[:route_url] = entity.route_url
    route.tags[:route_color] = entity.route_color
    route.tags[:route_text_color] = entity.route_text_color
    route
  end

end

class OldRoute < BaseRoute
  include OldTrackedByChangeset
  include HasAGeographicGeometry

  has_many :old_routes_serving_stop
  has_many :routes, through: :old_routes_serving_stop, source_type: 'Route'
end
