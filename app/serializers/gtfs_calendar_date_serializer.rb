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
#  service_id      :integer          not null
#
# Indexes
#
#  index_gtfs_calendar_dates_on_date             (date)
#  index_gtfs_calendar_dates_on_exception_type   (exception_type)
#  index_gtfs_calendar_dates_on_feed_version_id  (feed_version_id)
#  index_gtfs_calendar_dates_on_service_id       (service_id)
#

class GTFSCalendarDateSerializer < GTFSEntitySerializer
    attributes :service_id, :date, :exception_type
end
  
