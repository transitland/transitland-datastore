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

  before_validation :compute_and_set_hashes, :read_gtfs_info

  scope :where_active, -> {
    joins('INNER JOIN current_feeds ON feed_versions.id = current_feeds.active_feed_version_id')
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
  end

  def is_active_feed_version
    !!self.feed.active_feed_version && (self.feed.active_feed_version == self)
  end

  def open_gtfs
    fail StandardError.new('No file') unless file.present?
    filename = file.local_path_copying_locally_if_needed
    yield gtfs_source_build(filename)
    file.remove_any_local_cached_copies
  end

  def fetch_and_normalize
    fail StandardError.new('Files exist') if (file.present? || file_raw.present?)
    # Update fetched time
    self.fetched_at = DateTime.now
    # Download the raw feed
    gtfs_raw = gtfs_source_build(self.url)
    # Do we need to normalize?
    if self.url_fragment
      # Get temporary path
      Dir.mktmpdir do |dir|
        tmp_file_path = File.join(dir, 'normalized.zip')
        # Create normalize archive
        gtfs_raw.create_archive(tmp_file_path)
        gtfs_normalized = gtfs_source_build(tmp_file_path)
        # Update
        self.file = File.open(gtfs_normalized.archive)
        self.file_raw = File.open(gtfs_raw.archive)
      end
    else
      self.file = File.open(gtfs_raw.archive)
    end
    # Compute hashes
    compute_and_set_hashes
    # Cleanup
    self.file.remove_any_local_cached_copies if self.file
    self.file_raw.remove_any_local_cached_copies if self.file_raw
  end

  def url_fragment
    (self.url || "").partition("#").last.presence
  end

  def download_url
    if self.feed.license_redistribute.presence == 'no'
      nil
    elsif self.try(:file).try(:url)
      # we don't want to include any query parameters
      self.file.url.split('?').first
    end
  end

  private

  def gtfs_source_build(source)
    GTFS::Source.build(
      source,
      strict: false,
      tmpdir_basepath: Figaro.env.gtfs_tmpdir_basepath.presence
    )
  end

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

  def read_gtfs_info
    if file.present? && file_changed?
      open_gtfs do |gtfs|
        start_date, end_date = gtfs.service_period_range
        self.earliest_calendar_date ||= start_date
        self.latest_calendar_date ||= end_date
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
end
