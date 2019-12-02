# == Schema Information
#
# Table name: gtfs_calendars
#
#  id              :integer          not null, primary key
#  service_id      :string           not null
#  monday          :integer          not null
#  tuesday         :integer          not null
#  wednesday       :integer          not null
#  thursday        :integer          not null
#  friday          :integer          not null
#  saturday        :integer          not null
#  sunday          :integer          not null
#  start_date      :date             not null
#  end_date        :date             not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#  generated       :boolean          not null
#
# Indexes
#
#  index_gtfs_calendars_on_end_date                        (end_date)
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

class GTFSCalendarSerializer < GTFSEntitySerializer
    attributes :service_id, 
                :monday, 
                :tuesday, 
                :wednesday, 
                :thursday, 
                :friday, 
                :saturday, 
                :sunday, 
                :start_date, 
                :end_date
end
  
