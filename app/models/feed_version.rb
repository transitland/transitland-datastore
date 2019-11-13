# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer          not null
#  feed_type              :string           default("gtfs"), not null
#  file                   :string           default(""), not null
#  earliest_calendar_date :date             not null
#  latest_calendar_date   :date             not null
#  sha1                   :string           not null
#  md5                    :string
#  tags                   :hstore
#  fetched_at             :datetime         not null
#  imported_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  import_level           :integer          default(0), not null
#  url                    :string           default(""), not null
#  file_raw               :string
#  sha1_raw               :string
#  md5_raw                :string
#  file_feedvalidator     :string
#  deleted_at             :datetime
#  sha1_dir               :string
#
# Indexes
#
#  index_feed_versions_on_earliest_calendar_date  (earliest_calendar_date)
#  index_feed_versions_on_feed_type_and_feed_id   (feed_type,feed_id)
#  index_feed_versions_on_latest_calendar_date    (latest_calendar_date)
#

class FeedVersion < ActiveRecord::Base
  include HasTags
  include IsAnEntityWithIssues

  belongs_to :feed, polymorphic: true
  has_many :feed_version_infos, dependent: :destroy
  has_many :feed_version_imports, -> { order 'created_at DESC' }, dependent: :destroy
  has_many :gtfs_imports, -> { order 'created_at DESC' }, dependent: :destroy
  has_many :changesets_imported_from_this_feed_version, class_name: 'Changeset'

  has_many :entities_imported_from_feed
  has_many :imported_operators, -> { distinct }, through: :entities_imported_from_feed, source: :entity, source_type: 'Operator'
  has_many :imported_stops, -> { distinct }, through: :entities_imported_from_feed, source: :entity, source_type: 'Stop'
  has_many :imported_routes, -> { distinct }, through: :entities_imported_from_feed, source: :entity, source_type: 'Route'
  has_many :imported_route_stop_patterns, -> { distinct }, through: :entities_imported_from_feed, source: :entity, source_type: 'RouteStopPattern'
  has_many :imported_schedule_stop_pairs, class_name: 'ScheduleStopPair', dependent: :delete_all

  mount_uploader :file, FeedVersionUploader
  mount_uploader :file_raw, FeedVersionUploaderRaw
  mount_uploader :file_feedvalidator, FeedVersionUploaderFeedvalidator

  validates :sha1, presence: true, uniqueness: true
  validates :feed, presence: true

  before_validation :compute_and_set_hashes

  scope :where_active, -> {
    joins('INNER JOIN current_feeds ON feed_versions.id = current_feeds.active_feed_version_id')
  }

  scope :where_calendar_coverage_begins_at_or_before, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    where('earliest_calendar_date <= ?', date)
  }

  scope :where_calendar_coverage_begins_at_or_after, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    where('earliest_calendar_date >= ?', date)
  }

  scope :where_calendar_coverage_includes, -> (date) {
    date = date.is_a?(Date) ? date : Date.parse(date)
    where('earliest_calendar_date <= ?', date)
      .where('latest_calendar_date >= ?', date)
  }

  def succeeded(timestamp)
    self.update(imported_at: timestamp)
    self.feed.update(last_imported_at: self.imported_at)
  end

  def failed
    self.delete_schedule_stop_pairs!
  end

  def delete_schedule_stop_pairs!
    # Delete SSPs in batches.
    # http://stackoverflow.com/questions/8290900/
    self.imported_schedule_stop_pairs.select(:id).find_in_batches do |ssp_batch|
      ScheduleStopPair.delete(ssp_batch)
    end
  end

  def extend_schedule_stop_pairs_service_end_date(extend_from_date, extend_to_date)
    self.imported_schedule_stop_pairs.where('service_end_date >= ?', extend_from_date).select(:id).find_in_batches do |ssp_batch|
      ScheduleStopPair.where(id: ssp_batch).update_all(service_end_date: extend_to_date)
    end
    self.tags ||= {}
    self.tags["extend_from_date"] = extend_from_date
    self.tags["extend_to_date"] = extend_to_date
    self.update!(tags: self.tags)
  end

  def is_active_feed_version
    !!self.feed.active_feed_version && (self.feed.active_feed_version == self)
  end

  def import_status
    if self.feed_version_imports.count == 0
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

  def open_gtfs
    fail StandardError.new('No file') unless file.present?
    filename = file.local_path_copying_locally_if_needed
    gtfs = GTFS::Source.build(
      filename,
      strict: false,
      auto_detect_root: true,
      tmpdir_basepath: Figaro.env.gtfs_tmpdir_basepath.presence
    )
    file.remove_any_local_cached_copies
    gtfs
  end

  def download_url
    if self.feed.license_redistribute.presence == 'no'
      nil
    elsif self.try(:file).try(:url)
      # we don't want to include any query parameters
      self.file.url.split('?').first
    end
  end

  def feedvalidator_url
    if self.try(:file_feedvalidator).try(:url)
      # we don't want to include any query parameters
      self.file_feedvalidator.url.split('?').first
    end
  end

  private

  def compute_and_set_hashes
    if file.present? && file_changed?
      self.sha1 = Digest::SHA1.file(file.path).hexdigest
      self.md5  = Digest::MD5.file(file.path).hexdigest
    end
    if file_raw.present? && file_raw_changed?
      self.sha1_raw = Digest::SHA1.file(file_raw.path).hexdigest
      self.md5_raw  = Digest::MD5.file(file_raw.path).hexdigest
    end
  end

end
