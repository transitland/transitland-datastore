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
#  timezone                           :string
#  short_name                         :string
#  website                            :string
#  country                            :string
#  state                              :string
#  metro                              :string
#  edited_attributes                  :string           default([]), is an Array
#
# Indexes
#
#  #c_operators_cu_in_changeset_id_index  (created_or_updated_in_changeset_id)
#  index_current_operators_on_geometry    (geometry) USING gist
#  index_current_operators_on_onestop_id  (onestop_id) UNIQUE
#  index_current_operators_on_tags        (tags)
#  index_current_operators_on_updated_at  (updated_at)
#

class BaseOperator < ActiveRecord::Base
  self.abstract_class = true
  attr_accessor :serves, :does_not_serve
  validates :website, format: { with: URI.regexp }, if: Proc.new { |operator| operator.website.present? }
end

class Operator < BaseOperator
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include HasAGeographicGeometry
  include HasTags
  include UpdatedSince
  include IsAnEntityImportedFromFeeds
  include IsAnEntityWithIssues

  include CanBeSerializedToCsv
  def self.csv_column_names
    [
      'Onestop ID',
      'Name',
      'Short Name',
      'Country',
      'State',
      'Metro',
      'Timezone',
      'Website',
      'Transitland Feed Registry URL'
    ]
  end
  def csv_row_values
    [
      onestop_id,
      name,
      short_name,
      country,
      state,
      metro,
      timezone,
      tags.try(:fetch, :agency_url, nil),
      "https://transit.land/feed-registry/operators/#{onestop_id}"
    ]
  end

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :serves,
      :does_not_serve,
      :add_imported_from_feeds,
      :not_imported_from_feeds
    ],
    protected_attributes: [],
    sticky_attributes: [
      :short_name,
      :country,
      :metro,
      :state,
      :website
    ]
  })

  scope :with_feed, -> (feeds) {
    joins(:operators_in_feed).where({operators_in_feed: {feed_id: Array.wrap(feeds)}})
  }

  scope :without_feed, -> {
    joins('FULL OUTER JOIN current_operators_in_feed ON current_operators.id = current_operators_in_feed.operator_id WHERE current_operators_in_feed.id IS NULL')
  }

  def update_associations(changeset)
    update_entity_imported_from_feeds(changeset)
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
    operators_in_feed.each do |operator_in_feed|
      operator_in_feed.destroy_making_history(changeset: changeset)
    end
    return true
  end

  after_initialize :set_default_values
  after_save :bust_aggregate_cache

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

  private

  def set_default_values
    if self.new_record?
      self.tags ||= {}
    end
  end

  def bust_aggregate_cache
    Rails.cache.delete(Api::V1::OperatorsController::AGGREGATE_CACHE_KEY)
  end

end

class OldOperator < BaseOperator
  include OldTrackedByChangeset
  include HasAGeographicGeometry

  has_many :old_operators_serving_stop, as: :operator
  has_many :stops, through: :old_operators_serving_stop, source_type: 'Operator'

  has_many :routes, as: :operator
end
