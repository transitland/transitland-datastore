# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer
#  feed_type              :string
#  file                   :string
#  earliest_calendar_date :date
#  latest_calendar_date   :date
#  sha1                   :string
#  md5                    :string
#  tags                   :hstore
#  fetched_at             :datetime
#  imported_at            :datetime
#  created_at             :datetime
#  updated_at             :datetime
#  import_level           :integer          default(0)
#  url                    :string
#  file_raw               :string
#  sha1_raw               :string
#  md5_raw                :string
#
# Indexes
#
#  index_feed_versions_on_feed_type_and_feed_id  (feed_type,feed_id)
#

class FeedVersion < ActiveRecord::Base
  belongs_to :feed, polymorphic: true
  has_many :feed_version_imports, -> { order 'created_at DESC' }, dependent: :destroy
  has_many :changesets_imported_from_this_feed_version, class_name: 'Changeset'
  has_many :entities_imported_from_feed
  has_many :imported_operators, through: :entities_imported_from_feed, source: :entity, source_type: 'Operator'
  has_many :imported_stops, through: :entities_imported_from_feed, source: :entity, source_type: 'Stop'
  has_many :imported_routes, through: :entities_imported_from_feed, source: :entity, source_type: 'Route'
  has_many :imported_schedule_stop_pairs, class_name: 'ScheduleStopPair', dependent: :delete_all

  mount_uploader :file, FeedVersionUploader
  mount_uploader :file_raw, FeedVersionUploaderRaw

  validates :sha1, presence: true, uniqueness: true
  validates :feed, presence: true

  before_validation :compute_and_set_hashes, :read_gtfs_calendar_dates, :read_gtfs_feed_info

  def succeeded(timestamp)
    self.update(imported_at: timestamp)
    self.feed.update(last_imported_at: self.imported_at)
  end

  def failed
    self.delete_schedule_stop_pairs!
  end

  def delete_schedule_stop_pairs!
    self.imported_schedule_stop_pairs.delete_all
  end

  def is_active_feed_version
    !!self.feed.active_feed_version && (self.feed.active_feed_version == self)
  end

  def async_feed_eater(import_level=0)
    FeedEaterWorker.perform_async(
      self.feed.onestop_id,
      self.sha1,
      import_level
    )
  end

  def open_gtfs
    fail StandardError.new('No file') unless file.present?
    @gtfs ||= GTFS::Source.build(file.local_path_copying_locally_if_needed, {strict: false})
    @gtfs
  end

  def fetch_and_normalize
    fail StandardError.new('Files exist') if (file.present? || file_raw.present?)
    # Download the raw feed
    gtfs_raw = GTFS::Source.build(self.url, {strict: false})
    # Get temporary path
    Dir.mktmpdir do |dir|
      tmp_file_path = File.join(dir, 'normalized.zip')
      # Create normalize archive
      gtfs_raw.create_archive(tmp_file_path)
      gtfs_normalized = GTFS::Source.build(tmp_file_path, {strict: false})
      # Update
      self.fetched_at = DateTime.now
      self.file = File.open(gtfs_normalized.archive)
      self.file_raw = File.open(gtfs_raw.archive)
    end
    # Compute hashes
    compute_and_set_hashes

  def download_url
    if self.feed.license_redistribute.presence == 'no'
      nil
    elsif self.try(:file).try(:url)
      # we don't want to include any query parameters
      self.file.url.split('?').first
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

  def read_gtfs_calendar_dates
    if file.present? && file_changed?
      gtfs = open_gtfs
      start_date, end_date = gtfs.service_period_range
      self.earliest_calendar_date ||= start_date
      self.latest_calendar_date ||= end_date
    end
  end

  def read_gtfs_feed_info
    if file.present? && file_changed?
      gtfs = open_gtfs
      begin
        if gtfs.feed_infos.count > 0
          feed_info = gtfs.feed_infos[0]
          feed_version_tags = {
            feed_publisher_name: feed_info.feed_publisher_name,
            feed_publisher_url:  feed_info.feed_publisher_url,
            feed_lang:           feed_info.feed_lang,
            feed_start_date:     feed_info.feed_start_date,
            feed_end_date:       feed_info.feed_end_date,
            feed_version:        feed_info.feed_version,
            feed_id:             feed_info.feed_id
          }
          feed_version_tags.delete_if { |k, v| v.blank? }
          self.tags = feed_version_tags
        end
      rescue GTFS::InvalidSourceException
        return
      end
    end
  end
end
