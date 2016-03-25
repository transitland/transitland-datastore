# == Schema Information
#
# Table name: current_operators
#
#  id                                 :integer          not null, primary key
#  name                               :string
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  identifiers                        :string           default([]), is an Array
#  timezone                           :string
#  short_name                         :string
#  website                            :string
#  country                            :string
#  state                              :string
#  metro                              :string
#
# Indexes
#
#  #c_operators_cu_in_changeset_id_index   (created_or_updated_in_changeset_id)
#  index_current_operators_on_geometry     (geometry)
#  index_current_operators_on_identifiers  (identifiers)
#  index_current_operators_on_onestop_id   (onestop_id) UNIQUE
#  index_current_operators_on_tags         (tags)
#  index_current_operators_on_updated_at   (updated_at)
#

class BaseOperator < ActiveRecord::Base
  self.abstract_class = true
  attr_accessor :serves, :does_not_serve
  validates :website, format: { with: URI.regexp }, if: Proc.new { |operator| operator.website.present? }
end

class Operator < BaseOperator
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
      'Website'
    ]
  end
  def csv_row_values
    [
      onestop_id,
      name,
      tags.try(:fetch, :agency_url, '')
    ]
  end

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :serves,
      :does_not_serve,
      :identified_by,
      :not_identified_by
    ],
    protected_attributes: [
      :identifiers
    ]
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
    super(changeset)
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

  after_initialize :set_default_values

  has_many :operators_in_feed
  has_many :feeds, through: :operators_in_feed

  has_many :operators_serving_stop
  has_many :stops, through: :operators_serving_stop

  has_many :routes
  has_many :routes_serving_stop, through: :routes

  has_many :schedule_stop_pairs

  validates :name, presence: true

  def recompute_convex_hull_around_stops
    Operator.convex_hull(self.stops, projected: false)
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(entity, attrs={})
    # GTFS Constructor
    # Convert to TL Stops so geometry projection works properly...
    tl_stops = entity.stops.map { |stop| Stop.new(geometry: Stop::GEOFACTORY.point(*stop.coordinates)) }
    geohash = GeohashHelpers.fit(
      Stop::GEOFACTORY.collection(tl_stops.map { |stop| stop[:geometry] })
    )
    # Generate third Onestop ID component
    name = [entity.agency_name, entity.id, "unknown"]
      .select(&:present?)
      .first
    # Create Operator
    attrs[:geometry] = Operator.convex_hull(tl_stops, projected: false)
    attrs[:name] = name
    attrs[:onestop_id] = OnestopId.handler_by_model(self).new(
      geohash: geohash,
      name: name
    )
    operator = Operator.new(attrs)
    operator.tags ||= {}
    operator.tags[:agency_phone] = entity.agency_phone
    operator.tags[:agency_lang] = entity.agency_lang
    operator.tags[:agency_fare_url] = entity.agency_fare_url
    operator.tags[:agency_id] = entity.id
    operator.timezone = entity.agency_timezone
    operator.website = entity.agency_url
    operator
  end

  private

  def set_default_values
    if self.new_record?
      self.tags ||= {}
      self.identifiers ||= []
    end
  end

end

class OldOperator < BaseOperator
  include OldTrackedByChangeset
  include HasAGeographicGeometry

  has_many :old_operators_serving_stop, as: :operator
  has_many :stops, through: :old_operators_serving_stop, source_type: 'Operator'

  has_many :routes, as: :operator
end
