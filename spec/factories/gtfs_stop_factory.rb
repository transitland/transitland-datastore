# == Schema Information
#
# Table name: gtfs_stops
#
#  id                  :integer          not null, primary key
#  stop_id             :string           not null
#  stop_code           :string           not null
#  stop_name           :string           not null
#  stop_desc           :string           not null
#  zone_id             :string           not null
#  stop_url            :string           not null
#  location_type       :integer          not null
#  stop_timezone       :string           not null
#  wheelchair_boarding :integer          not null
#  geometry            :geography({:srid not null, point, 4326
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  feed_version_id     :integer          not null
#  parent_station      :integer
#  level_id            :string           not null
#
# Indexes
#
#  index_gtfs_stops_on_geometry        (geometry) USING gist
#  index_gtfs_stops_on_location_type   (location_type)
#  index_gtfs_stops_on_parent_station  (parent_station)
#  index_gtfs_stops_on_stop_code       (stop_code)
#  index_gtfs_stops_on_stop_desc       (stop_desc)
#  index_gtfs_stops_on_stop_id         (stop_id)
#  index_gtfs_stops_on_stop_name       (stop_name)
#  index_gtfs_stops_unique             (feed_version_id,stop_id) UNIQUE
#

FactoryGirl.define do
    factory :gtfs_stop do
      geometry { "POINT(#{rand(-124.4096..-114.1308)} #{rand(32.5343..42.0095)})" }
      stop_id 'test'
      stop_name 'Test Stop'
      stop_desc 'This is a test stop'
      stop_timezone 'America/Los_Angeles'
      location_type 0
      wheelchair_boarding 0
      association :feed_version
    end

    factory :gtfs_stop_bart, parent: :gtfs_stop, class: 'GTFSStop' do
    end
end  
