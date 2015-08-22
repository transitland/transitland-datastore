# == Schema Information
#
# Table name: feed_versions
#
#  id                     :integer          not null, primary key
#  feed_id                :integer
#  feed_type              :string
#  file_file_name         :string
#  file_content_type      :string
#  file_file_size         :integer
#  file_updated_at        :datetime
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
  belongs_to :feed, polymorphic: true
  has_many :feed_version_imports, dependent: :destroy

  has_attached_file :file
  validates_attachment_content_type :file, content_type: ['application/zip']

  validates :sha1, uniqueness: true

  before_post_process :compute_and_set_hashes, :read_gtfs_calendar_dates, :read_gtfs_feed_info

  private

  def compute_and_set_hashes
    temp_file_path = file.queued_for_write[:original].path
    self.sha1 ||= Digest::SHA1.file(temp_file_path).hexdigest
    self.md5  ||= Digest::MD5.file(temp_file_path).hexdigest
  end

  def read_gtfs_calendar_dates
    temp_file_path = file.queued_for_write[:original].path
    gtfs_file = GTFS::Source.build(temp_file_path, {strict: false})
    self.earliest_calendar_date ||= gtfs_file.calendars.map {|c| c.start_date}.min
    self.latest_calendar_date   ||= gtfs_file.calendars.map {|c| c.end_date}.max
  end
end
