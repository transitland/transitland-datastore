# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string
#  url                                :string
#  feed_format                        :string
#  tags                               :hstore
#  last_fetched_at                    :datetime
#  last_imported_at                   :datetime
#  license_name                       :string
#  license_url                        :string
#  license_use_without_attribution    :string
#  license_create_derived_product     :string
#  license_redistribute               :string
#  version                            :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#  created_or_updated_in_changeset_id :integer
#  geometry                           :geography({:srid geometry, 4326
#
# Indexes
#
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#

class BaseFeed < ActiveRecord::Base
  self.abstract_class = true

  PER_PAGE = 50

  has_many :feed_versions, dependent: :destroy
  has_many :feed_version_imports

  extend Enumerize
  enumerize :feed_format, in: [:gtfs]
  enumerize :license_use_without_attribution, in: [:yes, :no, :unknown]
  enumerize :license_create_derived_product, in: [:yes, :no, :unknown]
  enumerize :license_redistribute, in: [:yes, :no, :unknown]

  validates :url, presence: true
  validates :url, format: { with: URI.regexp }, if: Proc.new { |feed| feed.url.present? }
  validates :license_url, format: { with: URI.regexp }, if: Proc.new { |feed| feed.license_url.present? }

  attr_accessor :includes_operators, :does_not_include_operators
end

class Feed < BaseFeed
  self.table_name_prefix = 'current_'

  include HasAOnestopId
  include HasTags
  include UpdatedSince
  include HasAGeographicGeometry

  has_many :operators_in_feed
  has_many :operators, through: :operators_in_feed

  has_many :feed_imports, -> { order 'created_at DESC' }, dependent: :destroy

  has_many :entities_imported_from_feed
  has_many :imported_operators, through: :entities_imported_from_feed, source: :entity, source_type: 'Operator'
  has_many :imported_stops, through: :entities_imported_from_feed, source: :entity, source_type: 'Stop'
  has_many :imported_routes, through: :entities_imported_from_feed, source: :entity, source_type: 'Route'
  has_many :imported_schedule_stop_pairs, through: :entities_imported_from_feed, source: :entity, source_type: 'ScheduleStopPair'

  after_initialize :set_default_values

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [:includes_operators, :does_not_include_operators]
  })
  def self.after_create_making_history(created_model, changeset)
    created_model.includes_operators.each do |included_operator|
      operator = Operator.find_by!(onestop_id: included_operator[:operator_onestop_id])
      OperatorInFeed.create_making_history(
        changeset: changeset,
        new_attrs: {
          feed_id: created_model.id,
          operator_id: operator.id,
          gtfs_agency_id: included_operator[:gtfs_agency_id]
        }
      )
    end
    # No need to iterate through created_model.does_not_include_operators
    # since this is a brand new feed model.
  end
  def before_update_making_history(changeset)
    (self.includes_operators || []).each do |included_operator|
      operator = Operator.find_by!(onestop_id: included_operator[:operator_onestop_id])
      existing_relationship = OperatorInFeed.find_by(operator: operator, feed: self)
      if existing_relationship
          existing_relationship.update_making_history(
            changeset: changeset,
            new_attrs: {
              feed_id: self.id,
              operator_id: operator.id,
              gtfs_agency_id: included_operator[:gtfs_agency_id]
            }
          )
      else
        OperatorInFeed.create_making_history(
          changeset: changeset,
          new_attrs: {
            feed_id: self.id,
            operator_id: operator.id,
            gtfs_agency_id: included_operator[:gtfs_agency_id]
          }
        )
      end
    end
    (self.does_not_include_operators || []).each do |not_included_operator|
      operator = Operator.find_by!(onestop_id: not_included_operator[:operator_onestop_id])
      existing_relationship = OperatorInFeed.find_by(operator: operator, feed: self)
      if existing_relationship
        existing_relationship.destroy_making_history(changeset: changeset)
      end
    end
    super(changeset)
  end
  def before_destroy_making_history(changeset, old_model)
    operators_in_feed.each do |operator_in_feed|
      operator_in_feed.destroy_making_history(changeset: changeset)
    end
    return true
  end

  def fetch_and_check_for_updated_version
    begin
      logger.info "Fetching feed #{onestop_id} from #{url}"
      begin
        feed_version = self.feed_versions.create(file: self.url)
      rescue OpenURI::HTTPError => exception
        logger.error "Error downloading #{url}: #{exception}"
        logger.error exception.backtrace
        return false
      end

      if feed_version.persisted?
        logger.info "File downloaded from #{url} has a new sha1 hash"
        true
      else
        logger.info "File downloaded from #{url} has same sha1 hash as last imported version (or another error fetching file)"
        false
      end
    rescue
      logger.error "Error fetching feed ##{onestop_id}"
      logger.error $!.message
      logger.error $!.backtrace
      false
    end
  end

  def self.fetch_and_check_for_updated_version(feed_onestop_ids = [])
    feeds_with_updated_versions = []
    feeds = feed_onestop_ids.length > 0 ? where(onestop_id: feed_onestop_ids) : where('')
    feeds.each do |feed|
      is_updated_version = feed.fetch_and_check_for_updated_version
      feeds_with_updated_versions << feed if is_updated_version
    end
    feeds_with_updated_versions
  end

  def set_bounding_box_from_stops(stops)
    stop_features = Stop::GEOFACTORY.collection(stops.map { |stop| stop.geometry(as: :wkt) })
    bounding_box = RGeo::Cartesian::BoundingBox.create_from_geometry(stop_features)
    self.geometry = bounding_box.to_geometry
  end

  private

  def set_default_values
    if self.new_record?
      self.tags ||= {}
      self.feed_format ||= 'gtfs'
      self.license_use_without_attribution ||= 'unknown'
      self.license_create_derived_product ||= 'unknown'
      self.license_redistribute ||= 'unknown'
    end
  end
end

class OldFeed < BaseFeed
  include OldTrackedByChangeset

  has_many :old_operators_in_feed, as: :feed
  has_many :operators, through: :old_operators_in_feed, source_type: 'Feed'
end
