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
#  index_current_operators_on_identifiers  (identifiers)
#  index_current_operators_on_onestop_id   (onestop_id) UNIQUE
#  index_current_operators_on_tags         (tags)
#  index_current_operators_on_updated_at   (updated_at)
#

class BaseOperator < ActiveRecord::Base
  self.abstract_class = true

  PER_PAGE = 50

  attr_accessor :serves, :does_not_serve

  has_many :entities_imported_from_feed, as: :entity
  has_many :feeds, through: :entities_imported_from_feed

  validates :website, format: { with: URI.regexp }, if: Proc.new { |operator| operator.website.present? }
end

class Operator < BaseOperator
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include IsAnEntityWithIdentifiers
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince

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
    virtual_attributes: [:serves, :does_not_serve, :identified_by, :not_identified_by, :imported_from_feed_onestop_id]
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

  def imported_from_feed_onestop_id=(value)
    self.feeds << Feed.find_by!(onestop_id: value)
  end

  has_many :operators_serving_stop
  has_many :stops, through: :operators_serving_stop

  has_many :routes
  has_many :routes_serving_stop, through: :routes

  validates :name, presence: true

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(entity, stops)
    # GTFS Constructor
    geohash = GeohashHelpers.fit(stops.map { |i| i[:geometry] })
    geometry = Operator.convex_hull(stops, as: :wkt, projected: false)
    onestop_id = OnestopId.new(
      entity_prefix: 'o',
      geohash: geohash,
      name: entity.name.downcase.gsub(/\W+/, '')
    )
    operator = Operator.new(
      name: entity.name,
      onestop_id: onestop_id.to_s,
      identifiers: [entity.id]
    )
    operator[:geometry] = geometry
    # Copy over GTFS attributes to tags
    operator.tags ||= {}
    operator.tags[:agency_phone] = entity.phone
    operator.tags[:agency_lang] = entity.lang
    operator.tags[:agency_fare_url] = entity.fare_url
    operator.tags[:agency_id] = entity.id
    operator.timezone = entity.timezone
    operator.website = entity.url
    operator
  end

end

class OldOperator < BaseOperator
  include OldTrackedByChangeset
  include HasAGeographicGeometry

  has_many :old_operators_serving_stop, as: :operator
  has_many :stops, through: :old_operators_serving_stop, source_type: 'Operator'

  has_many :routes, as: :operator
end
