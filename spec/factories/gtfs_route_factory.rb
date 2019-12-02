# == Schema Information
#
# Table name: gtfs_routes
#
#  id               :integer          not null, primary key
#  route_id         :string           not null
#  route_short_name :string           not null
#  route_long_name  :string           not null
#  route_desc       :string           not null
#  route_type       :integer          not null
#  route_url        :string           not null
#  route_color      :string           not null
#  route_text_color :string           not null
#  route_sort_order :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  feed_version_id  :integer          not null
#  agency_id        :integer          not null
#
# Indexes
#
#  index_gtfs_routes_on_agency_id                  (agency_id)
#  index_gtfs_routes_on_feed_version_id_agency_id  (feed_version_id,id,agency_id)
#  index_gtfs_routes_on_route_desc                 (route_desc)
#  index_gtfs_routes_on_route_id                   (route_id)
#  index_gtfs_routes_on_route_long_name            (route_long_name)
#  index_gtfs_routes_on_route_short_name           (route_short_name)
#  index_gtfs_routes_on_route_type                 (route_type)
#  index_gtfs_routes_unique                        (feed_version_id,route_id) UNIQUE
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
