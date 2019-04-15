# == Schema Information
#
# Table name: gtfs_calendar_dates
#
#  id              :integer          not null, primary key
#  date            :date             not null
#  exception_type  :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#  service_id      :integer
#
# Indexes
#
#  index_gtfs_calendar_dates_on_date             (date)
#  index_gtfs_calendar_dates_on_exception_type   (exception_type)
#  index_gtfs_calendar_dates_on_feed_version_id  (feed_version_id)
#  index_gtfs_calendar_dates_on_service_id       (service_id)
#

class GTFSCalendarDate < ActiveRecord::Base
  include GTFSEntity
  belongs_to :feed_version
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :service_id, presence: true
  validates :date, presence: true
  validates :exception_type, presence: true
end
