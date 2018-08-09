# == Schema Information
#
# Table name: gtfs_calendars
#
#  id              :integer          not null, primary key
#  service_id      :string           not null
#  monday          :boolean          not null
#  tuesday         :boolean          not null
#  wednesday       :boolean          not null
#  thursday        :boolean          not null
#  friday          :boolean          not null
#  saturday        :boolean          not null
#  sunday          :boolean          not null
#  start_date      :date             not null
#  end_date        :date             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#
# Indexes
#
#  index_gtfs_calendars_on_end_date                        (end_date)
#  index_gtfs_calendars_on_feed_version_id                 (feed_version_id)
#  index_gtfs_calendars_on_feed_version_id_and_service_id  (feed_version_id,service_id) UNIQUE
#  index_gtfs_calendars_on_friday                          (friday)
#  index_gtfs_calendars_on_monday                          (monday)
#  index_gtfs_calendars_on_saturday                        (saturday)
#  index_gtfs_calendars_on_service_id                      (service_id)
#  index_gtfs_calendars_on_start_date                      (start_date)
#  index_gtfs_calendars_on_sunday                          (sunday)
#  index_gtfs_calendars_on_thursday                        (thursday)
#  index_gtfs_calendars_on_tuesday                         (tuesday)
#  index_gtfs_calendars_on_wednesday                       (wednesday)
#

class GTFSCalendar < ActiveRecord::Base
  include GTFSEntity
  belongs_to :feed_version
  validates :feed_version, presence: true, unless: :skip_association_validations
  validates :service_id, presence: true
  validates :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, inclusion: { in: [true, false] }
  has_many :exceptions, -> (c) { where("gtfs_calendar_dates.feed_version_id = :feed_version_id", feed_version_id: c.feed_version_id) }, class_name: 'GTFSCalendarDate', primary_key: 'service_id', foreign_key: :service_id

  def service_added_dates
    exceptions.map { |i| i.date if i.exception_type == 1 }.compact.uniq
  end

  def service_except_dates
    exceptions.map { |i| i.date if i.exception_type == 2 }.compact.uniq
  end

  def service_days_of_week
    [monday, tuesday, wednesday, thursday, friday, saturday, sunday]
  end
end
