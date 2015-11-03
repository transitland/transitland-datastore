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
#
# Indexes
#
#  index_feed_versions_on_feed_type_and_feed_id  (feed_type,feed_id)
#

class FeedVersion < ActiveRecord::Base
  PER_PAGE = 50

  belongs_to :feed, polymorphic: true
  has_many :feed_version_imports, -> { order 'created_at DESC' }, dependent: :destroy

  has_many :entities_imported_from_feed
  has_many :imported_operators, through: :entities_imported_from_feed, source: :entity, source_type: 'Operator'
  has_many :imported_stops, through: :entities_imported_from_feed, source: :entity, source_type: 'Stop'
  has_many :imported_routes, through: :entities_imported_from_feed, source: :entity, source_type: 'Route'
  has_many :imported_schedule_stop_pairs, through: :entities_imported_from_feed, source: :entity, source_type: 'ScheduleStopPair'

  mount_uploader :file, FeedVersionUploader

  validates :sha1, uniqueness: true

  before_validation :compute_and_set_hashes, :read_gtfs_calendar_dates, :read_gtfs_feed_info

  private

  def compute_and_set_hashes
    if file.present? && file_changed?
      self.sha1 = Digest::SHA1.file(file.path).hexdigest
      self.md5  = Digest::MD5.file(file.path).hexdigest
    end
  end

  def read_gtfs_calendar_dates
    if file.present? && file_changed?
      gtfs_file = GTFS::Source.build(file.path, {strict: false})
      self.earliest_calendar_date ||= gtfs_file.calendars.map {|c| c.start_date}.min
      self.latest_calendar_date   ||= gtfs_file.calendars.map {|c| c.end_date}.max
    end
  end

  def read_gtfs_feed_info
    if file.present? && file_changed?
      gtfs_file = GTFS::Source.build(file.path, {strict: false})
      begin
        if gtfs_file.feed_infos.count > 0
          feed_info = gtfs_file.feed_infos[0]
          feed_version_tags = {
            feed_publisher_name: feed_info.feed_publisher_name,
            feed_publisher_url:  feed_info.feed_publisher_url,
            feed_lang:           feed_info.feed_lang,
            feed_start_date:     feed_info.feed_start_date,
            feed_end_date:       feed_info.feed_end_date,
            feed_version:        feed_info.feed_version
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
