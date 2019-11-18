# == Schema Information
#
# Table name: current_feeds
#
#  id                                 :integer          not null, primary key
#  onestop_id                         :string           not null
#  url                                :string
#  spec                               :string           default("gtfs"), not null
#  tags                               :hstore
#  last_fetched_at                    :datetime
#  last_imported_at                   :datetime
#  version                            :integer
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  created_or_updated_in_changeset_id :integer
#  geometry                           :geography({:srid geometry, 4326
#  active_feed_version_id             :integer
#  edited_attributes                  :string           default([]), is an Array
#  name                               :string
#  type                               :string
#  auth                               :jsonb            not null
#  urls                               :jsonb            not null
#  deleted_at                         :datetime
#  last_successful_fetch_at           :datetime
#  last_fetch_error                   :string           default(""), not null
#  license                            :jsonb            not null
#  other_ids                          :jsonb            not null
#  associated_feeds                   :jsonb            not null
#  languages                          :jsonb            not null
#  feed_namespace_id                  :string           default(""), not null
#  file                               :string           default(""), not null
#
# Indexes
#
#  index_current_feeds_on_active_feed_version_id              (active_feed_version_id)
#  index_current_feeds_on_auth                                (auth)
#  index_current_feeds_on_created_or_updated_in_changeset_id  (created_or_updated_in_changeset_id)
#  index_current_feeds_on_geometry                            (geometry) USING gist
#  index_current_feeds_on_onestop_id                          (onestop_id) UNIQUE
#  index_current_feeds_on_urls                                (urls)
#

class BaseFeed < ActiveRecord::Base
  self.abstract_class = true
end

class Feed < BaseFeed
  self.table_name = 'current_feeds'

  include HasAOnestopId
  include HasTags
  include UpdatedSince
  include HasAGeographicGeometry
  include IsAnEntityWithIssues
  include IsAnEntityImportedFromFeeds

  include CanBeSerializedToCsv
  def self.csv_column_names
    [
      'Onestop ID',
      'Name',
      'URL'
    ]
  end
  def csv_row_values
    [
      onestop_id,
      name,
      url
    ]
  end

  extend Enumerize
  enumerize :license_use_without_attribution, in: [:yes, :no, :unknown]
  enumerize :license_create_derived_product, in: [:yes, :no, :unknown]
  enumerize :license_redistribute, in: [:yes, :no, :unknown]
  
  attr_accessor :includes_operators, :does_not_include_operators

  validates :license_url, format: { with: URI.regexp }, if: Proc.new { |feed| feed.license_url.present? }
  validate :validate_urls

  has_many :feed_versions, -> { order 'earliest_calendar_date' }, dependent: :destroy, as: :feed
  has_many :feed_version_imports, -> { order 'created_at DESC' }, through: :feed_versions
  has_many :gtfs_imports, -> { order 'created_at DESC' }, through: :feed_versions
  belongs_to :active_feed_version, class_name: 'FeedVersion'

  has_many :operators_in_feed
  has_many :operators, -> { distinct }, through: :operators_in_feed

  has_many :entities_imported_from_feed
  has_many :imported_operators, -> { distinct }, through: :entities_imported_from_feed, source: :entity, source_type: 'Operator'
  has_many :imported_stops, -> { distinct }, through: :entities_imported_from_feed, source: :entity, source_type: 'Stop'
  has_many :imported_routes, -> { distinct }, through: :entities_imported_from_feed, source: :entity, source_type: 'Route'
  has_many :imported_route_stop_patterns, -> { distinct }, through: :entities_imported_from_feed, source: :entity, source_type: 'RouteStopPattern'
  has_many :imported_schedule_stop_pairs, class_name: 'ScheduleStopPair', dependent: :delete_all

  has_many :changesets_imported_from_this_feed, class_name: 'Changeset'

  after_initialize :set_default_values

  scope :where_latest_fetch_exception, -> (flag) {
    if flag
      where("current_feeds.id IN (SELECT entities_with_issues.entity_id FROM entities_with_issues INNER JOIN issues ON entities_with_issues.issue_id=issues.id WHERE issues.issue_type IN ('feed_fetch_invalid_zip', 'feed_fetch_invalid_url', 'feed_fetch_invalid_response', 'feed_fetch_invalid_source') AND entities_with_issues.entity_type='Feed')")
    else
      where("current_feeds.id NOT IN (SELECT entities_with_issues.entity_id FROM entities_with_issues INNER JOIN issues ON entities_with_issues.issue_id=issues.id WHERE issues.issue_type IN ('feed_fetch_invalid_zip', 'feed_fetch_invalid_url', 'feed_fetch_invalid_response', 'feed_fetch_invalid_source') AND entities_with_issues.entity_type='Feed')")
    end
  }

  scope :where_active_feed_version_import_level, -> (import_level) {
    import_level = import_level.to_i
    joins(:active_feed_version)
      .where('feed_versions.import_level = ?', import_level)
  }

  scope :where_active_feed_version_valid, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    joins(:active_feed_version)
      .where('feed_versions.latest_calendar_date > ?', date)
      .where('feed_versions.earliest_calendar_date < ?', date)
  }

  scope :where_active_feed_version_expired, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    joins(:active_feed_version)
      .where('feed_versions.latest_calendar_date < ?', date)
  }

  scope :where_active_feed_version_update, -> {
    # Find feeds that have a feed_version newer than
    #   the current active_feed_version
    joins(%{
      INNER JOIN (
        SELECT DISTINCT feed_versions.feed_id
        FROM feed_versions
        INNER JOIN (
          SELECT feed_versions.feed_id AS feed_id, feed_versions.created_at AS created_at_active
          FROM feed_versions
          INNER JOIN current_feeds ON current_feeds.active_feed_version_id = feed_versions.id
          GROUP BY feed_versions.feed_id, feed_versions.created_at
        ) feed_versions_active ON feed_versions.feed_id = feed_versions_active.feed_id
        WHERE feed_versions.created_at > feed_versions_active.created_at_active
      ) feeds_superseded
      ON current_feeds.id = feeds_superseded.feed_id
    })
  }

  scope :with_latest_feed_version_import, -> {
    # Get the highest fvi id (=~ created_at) for each feed,
    joins(%{
      INNER JOIN (
        SELECT fv.feed_id, MAX(fvi.id) fvi_max_id
        FROM feed_versions fv
        INNER JOIN feed_version_imports fvi ON (fvi.feed_version_id = fv.id)
        GROUP BY (fv.feed_id)
      ) fvi_max
      ON current_feeds.id = fvi_max.feed_id
    })
      .joins('INNER JOIN feed_version_imports latest_feed_version_import ON (latest_feed_version_import.id = fvi_max.fvi_max_id)')
      .select(['current_feeds.*', 'latest_feed_version_import.id AS latest_feed_version_import_id'])
  }

  scope :where_latest_feed_version_import_status, -> (import_status) {
    # filter by latest fvi's success status.
    with_latest_feed_version_import.where('latest_feed_version_import.success': import_status)
    # Another approach, preserved here for now:
    # see: http://stackoverflow.com/questions/121387/fetch-the-row-which-has-the-max-value-for-a-column/123481#123481
    # LEFT OUTER JOIN feed_version_imports fvi2 ON (
    #   fvi1.feed_version_id = fvi2.feed_version_id AND
    #   fvi1.created_at < fvi2.created_at
    # )
    # WHERE fvi2.id IS NULL GROUP BY (fv.feed_id)
  }


  # "static_current": { "type": "string" },
  # "static_historic": { "type": "string" },
  # "static_planned": { "type": "string" },
  # "static_hypothetical": { "type": "string" },
  # "realtime_vehicle_positions": { "type": "string" },
  # "realtime_trip_updates": { "type": "string" },
  # "realtime_alerts": { "type": "string" }
  def valid_url_types
    ['static_current', 'static_historic', 'static_planned', 'static_hypothetical']
  end

  def validate_urls
    vt = self.valid_url_types
    self.urls ||= {}    
    self.urls.each do |k,v|
      errors.add(:urls, "invalid url type: #{k}") unless vt.include?(k)
      errors.add(:urls, "invalid url: #{v}") unless v =~ URI.regexp
    end
    if self.urls.length == 0 
      errors.add(:urls, "at least one url is required")
    end
  end

  def feed_format
    'gtfs'
  end

  def self.feed_version_update_statistics(feed)
    fvs = feed.feed_versions.to_a
    fvs_stats = fvs.select { |a| a.url.presence && a.fetched_at && a.earliest_calendar_date && a.latest_calendar_date }.sort_by { |a| a.fetched_at }
    result = {
      feed_onestop_id: feed.onestop_id,
      feed_versions_total: fvs.count,
      feed_versions_filtered: fvs_stats.count,
    }
    return result if fvs_stats.size < 1
    # Duration is a counted value; use float to report average.
    result[:scheduled_service_duration_average] = (fvs_stats.map { |a| a.latest_calendar_date.to_date - a.earliest_calendar_date.to_date}.sum / fvs_stats.size).to_f

    fvs_pairs = fvs_stats[0..-2].zip(fvs_stats[1..-1])
    if fvs_pairs.size > 0
      result[:feed_versions_filtered_sha1] = fvs_stats.map { |a| a.sha1 }
      # The precision of fetched_at is 1 day; report as an int
      result[:fetched_at_frequency] = (fvs_pairs.map { |a,b| b.fetched_at.to_date - a.fetched_at.to_date }.sum / fvs_pairs.size).to_i
      # Duration is a counted value; use float to report average.
      result[:scheduled_service_overlap_average] = (fvs_pairs.map { |a,b| a.latest_calendar_date.to_date - b.earliest_calendar_date.to_date }.sum / fvs_pairs.size).to_f
    end
    result
  end

  include CurrentTrackedByChangeset
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :includes_operators,
      :does_not_include_operators
    ],
    protected_attributes: []
  })

  def update_associations(changeset)
    (self.includes_operators || []).uniq.each do |included_operator|
      operator = Operator.find_by!(onestop_id: included_operator[:operator_onestop_id])
      existing_relationship = OperatorInFeed.find_by(
        operator: operator,
        gtfs_agency_id: included_operator[:gtfs_agency_id],
        feed: self
      )
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
    (self.does_not_include_operators || []).uniq.each do |not_included_operator|
      operator = Operator.find_by!(onestop_id: not_included_operator[:operator_onestop_id])
      existing_relationship = OperatorInFeed.find_by(
        operator: operator,
        gtfs_agency_id: not_included_operator[:gtfs_agency_id],
        feed: self
      )
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

  def activate_feed_version(feed_version_sha1, import_level)
    feed_version = self.feed_versions.find_by!(sha1: feed_version_sha1)
    self.transaction do
      self.update!(active_feed_version: feed_version)
      feed_version.update!(import_level: import_level)
    end
  end

  def deactivate_feed_version(feed_version_sha1)
    feed_version = self.feed_versions.find_by!(sha1: feed_version_sha1)
    if feed_version == self.active_feed_version
      fail ArgumentError.new('Cannot deactivate current active_feed_version')
    else
      feed_version.delete_schedule_stop_pairs!
    end
  end

  def set_bounding_box_from_stops(stops)
    stop_features = Stop::GEOFACTORY.collection(stops.map { |stop| stop.geometry(as: :wkt) })
    bounding_box = RGeo::Cartesian::BoundingBox.create_from_geometry(stop_features)
    self.geometry = bounding_box.to_geometry
  end

  def import_status
    if self.feed_version_imports.count == 0
      :never_imported
    elsif self.feed_version_imports.first.success == false
      :most_recent_failed
    elsif self.feed_version_imports.first.success == true
      :most_recent_succeeded
    elsif self.feed_version_imports.first.success == nil || self.last_imported_at.blank?
      :in_progress
    else
      :unknown
    end
  end

  STATUS_VALUES = ['active','replaced','unreachable','unpublished','outdated','broken', nil]
  def status=(value)
    value = value.to_s.presence
    fail Exception.new("Invalid status: #{value}") unless STATUS_VALUES.include?(value)
    tags['status'] = value
  end

  def status
    tags['status'] || 'active'
  end

  IMPORT_POLICY_VALUES = ['manual','immediately','weekly','daily', nil]
  def import_policy=(value)
    value = value.to_s.presence
    fail Exception.new("Invalid import_policy: #{value}") unless IMPORT_POLICY_VALUES.include?(value)
    tags['import_policy'] = value
  end

  def import_policy
    value = tags['import_policy']
    if tags['manual_import'] == 'true'
      value ||= 'manual'
    end
    value
  end

  def url
    return "" if self.urls.nil?
    return self.urls["static_current"]
  end

  def url=(value)
    if self.urls.nil?
      self.urls = {}
    end
    return if value.nil? # required for changesets to work, assign_attributes is unordered
    self.urls["static_current"] = value
  end

  def ssl_verify
    if tags['ssl_verify'] == 'false'
      return false
    else
      return true
    end
  end

  # dmfr backwards compat

  def license_name
    (self.license || {})["spdx_identifier"].presence
  end

  def license_url
    (self.license || {})["url"].presence
  end

  def license_use_without_attribution
    (self.license || {})["use_without_attribution"].presence || "unknown"
  end

  def license_create_derived_product
    (self.license || {})["create_derived_product"].presence || "unknown"
  end

  def license_redistribute
    (self.license || {})["redistribution_allowed"].presence || "unknown"
  end

  def license_attribution_text
    (self.license || {})["attribution_text"].presence
  end

  def license_name=(value)
    self.license ||= {}
    self.license["spdx_identifier"] = value
  end

  def license_url=(value)
    self.license ||= {}
    self.license["url"] = value
  end

  def license_use_without_attribution=(value)
    self.license ||= {}
    self.license["use_without_attribution"] = value
  end

  def license_create_derived_product=(value)
    self.license ||= {}
    self.license["create_derived_product"] = value
  end

  def license_redistribute=(value)
    self.license ||= {}
    self.license["redistribution_allowed"] = value
  end

  def license_attribution_text=(value)
    self.license ||= {}
    self.license["attribution_text"] = value
  end

  private

  def set_default_values
    if self.new_record?
      self.tags ||= {}
      self.license ||= {}
      self.license_use_without_attribution ||= 'unknown'
      self.license_create_derived_product ||= 'unknown'
      self.license_redistribute ||= 'unknown'
    end
  end
end

class GTFSStaticFeed < Feed
end

class GTFSRealtimeFeed < Feed
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :includes_operators,
      :does_not_include_operators
    ],
    protected_attributes: []
  })
  
  # "realtime_vehicle_positions": { "type": "string" },
  # "realtime_trip_updates": { "type": "string" },
  # "realtime_alerts": { "type": "string" }
  def valid_url_types
    ['realtime_vehicle_positions', 'realtime_trip_updates', 'realtime_alerts']
  end

  def url=(value)
  end

  def feed_format
    'gtfs-rt'
  end

end

class OldFeed < ActiveRecord::Base
  self.table_name = 'old_feeds'
  include OldTrackedByChangeset
  has_many :old_operators_in_feed, as: :feed
  has_many :operators, through: :old_operators_in_feed, source_type: 'Feed'
end

class OldGTFSRealtimeFeed < OldFeed
end
