# == Schema Information
#
# Table name: gtfs_trips
#
#  id                    :integer          not null, primary key
#  service_id            :string           not null
#  trip_id               :string           not null
#  trip_headsign         :string
#  trip_short_name       :string
#  direction_id          :integer
#  block_id              :string
#  wheelchair_accessible :integer
#  bikes_allowed         :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  feed_version_id       :integer          not null
#  entity_id             :integer
#  route_id              :integer          not null
#  shape_id              :integer
#
# Indexes
#
#  index_gtfs_trips_on_entity_id        (entity_id)
#  index_gtfs_trips_on_feed_version_id  (feed_version_id)
#  index_gtfs_trips_on_route_id         (route_id)
#  index_gtfs_trips_on_service_id       (service_id)
#  index_gtfs_trips_on_shape_id         (shape_id)
#  index_gtfs_trips_on_trip_headsign    (trip_headsign)
#  index_gtfs_trips_on_trip_id          (trip_id)
#  index_gtfs_trips_on_trip_short_name  (trip_short_name)
#  index_gtfs_trips_unique              (feed_version_id,trip_id) UNIQUE
#

FactoryGirl.define do
    factory :gtfs_route do
        route_id "test"
        route_short_name "Test"
        route_long_name "Test Route"
        route_desc "This is a test route"
        route_type 1
        route_url "http://example.com/routes/test"
        route_color "0099cc"
        route_text_color "000000"
        association :agency, factory: :gtfs_agency
        association :feed_version
    end

    factory :gtfs_route_bart_01DCM21, parent: :gtfs_route, class: GTFSRoute do
        route_id "11"
        route_short_name "BART"
        route_long_name "Dublin/Pleasanton - Daly City"
        route_desc nil
        route_type 1
        route_url "http://www.bart.gov/schedules/bylineresults?route=11"
        route_color "0099cc"
        route_text_color nil
        association :agency, factory: :gtfs_agency_bart
    end
end  
