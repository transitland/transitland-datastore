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
#  latest_fetch_exception_log         :text
#  license_attribution_text           :text
#  active_feed_version_id             :integer
#
# Indexes
#
#  index_current_feeds_on_active_feed_version_id              (active_feed_version_id)
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#  index_current_feeds_on_geometry                            (geometry)
#

class BaseFeed < ActiveRecord::Base
  self.abstract_class = true

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

  has_many :feed_versions, -> { order 'created_at DESC' }, dependent: :destroy, as: :feed
  has_many :feed_version_imports, -> { order 'created_at DESC' }, through: :feed_versions
  belongs_to :active_feed_version, class_name: 'FeedVersion'

  has_many :operators_in_feed
  has_many :operators, through: :operators_in_feed

  has_many :entities_imported_from_feed
  has_many :imported_operators, through: :entities_imported_from_feed, source: :entity, source_type: 'Operator'
  has_many :imported_stops, through: :entities_imported_from_feed, source: :entity, source_type: 'Stop'
  has_many :imported_routes, through: :entities_imported_from_feed, source: :entity, source_type: 'Route'
  has_many :imported_schedule_stop_pairs, through: :entities_imported_from_feed, source: :entity, source_type: 'ScheduleStopPair'
  has_many :imported_route_stop_patterns, through: :entities_imported_from_feed, source: :entity, source_type: 'RouteStopPattern'
  has_many :imported_schedule_stop_pairs, class_name: 'ScheduleStopPair', dependent: :delete_all

  has_many :changesets_imported_from_this_feed, class_name: 'Changeset'

  after_initialize :set_default_values

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :includes_operators,
      :does_not_include_operators
    ],
    protected_attributes: [
      :identifiers
    ]
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

  def fetch_and_return_feed_version
    # Check Feed URL for new files.
    fetch_exception_log = nil
    feed_version = FeedVersion.new(feed: self, url: self.url)
    logger.info "Fetching feed #{onestop_id} from #{url}"
    # Try to fetch and normalize feed; log error
    begin
      feed_version.fetch_and_normalize
    rescue GTFS::InvalidSourceException => e
      fetch_exception_log = e.message
      if e.backtrace.present?
        fetch_exception_log << "\n"
        fetch_exception_log << e.backtrace.join("\n")
      end
      logger.error fetch_exception_log
    ensure
      self.update(
        latest_fetch_exception_log: fetch_exception_log,
        last_fetched_at: feed_version.fetched_at || DateTime.now
      )
    end
    # Return if error; will fail if no sha1 from a successful fetch.
    return unless feed_version.valid?
    # Check for known Feed Version
    feed_version = self.feed_versions.find_by(sha1: feed_version.sha1) || feed_version
    if feed_version.persisted?
      logger.info "File downloaded from #{url} has an existing sha1 hash: #{feed_version.sha1}"
    else
      logger.info "File downloaded from #{url} has a new sha1 hash: #{feed_version.sha1}"
      feed_version.save!
    end
    # Return found/created FeedVersion
    feed_version
  end

  def activate_feed_version(feed_version_sha1, import_level)
    self.transaction do
      feed_version = self.feed_versions.find_by!(sha1: feed_version_sha1)
      self.update!(active_feed_version: feed_version)
      feed_version.update!(import_level: import_level)
    end
  end

  def self.async_fetch_all_feeds
    workers = []
    Feed.find_each do |feed|
      workers << feed.async_fetch_feed_version
    end
    workers
  end

  def async_fetch_feed_version
    FeedFetcherWorker.perform_async(onestop_id)
  end

  def set_bounding_box_from_stops(stops)
    stop_features = Stop::GEOFACTORY.collection(stops.map { |stop| stop.geometry(as: :wkt) })
    bounding_box = RGeo::Cartesian::BoundingBox.create_from_geometry(stop_features)
    self.geometry = bounding_box.to_geometry
  end

  def import_status
    if self.last_imported_at.blank? && self.feed_version_imports.count == 0
      :never_imported
    elsif self.feed_version_imports.first.success == false
      :most_recent_failed
    elsif self.feed_version_imports.first.success == true
      :most_recent_succeeded
    elsif self.feed_version_imports.first.success == nil
      :in_progress
    else
      :unknown
    end
  end

  ##### FromGTFS ####
  include FromGTFS
  def self.from_gtfs(entity, attrs={})
    # Entity is a feed.
    visited_stops = Set.new
    entity.agencies.each { |agency| visited_stops |= agency.stops }
    coordinates = Stop::GEOFACTORY.collection(
      visited_stops.map { |stop| Stop::GEOFACTORY.point(*stop.coordinates) }
    )
    geohash = GeohashHelpers.fit(coordinates)
    geometry = RGeo::Cartesian::BoundingBox.create_from_geometry(coordinates)
    # Generate third Onestop ID component
    feed_id = nil
    if entity.file_present?('feed_info.txt')
      feed_info = entity.feed_infos.first
      feed_id = feed_info.feed_id if feed_info
    end
    name_agencies = entity.agencies.select { |agency| agency.stops.size > 0 }.map(&:agency_name).join('~')
    name_url = Addressable::URI.parse(attrs[:url]).host.gsub(/[^a-zA-Z0-9]/, '') if attrs[:url]
    name = feed_id.presence || name_agencies.presence || name_url.presence || 'unknown'
    # Create Feed
    attrs[:geometry] = geometry.to_geometry
    attrs[:onestop_id] = OnestopId.handler_by_model(self).new(
      geohash: geohash,
      name: name
    )
    feed = Feed.new(attrs)
    feed.tags ||= {}
    feed.tags[:feed_id] = feed_id if feed_id
    feed
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
