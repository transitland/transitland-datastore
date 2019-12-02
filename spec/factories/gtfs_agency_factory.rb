# == Schema Information
#
# Table name: gtfs_agencies
#
#  id              :integer          not null, primary key
#  agency_id       :string           not null
#  agency_name     :string           not null
#  agency_url      :string           not null
#  agency_timezone :string           not null
#  agency_lang     :string           not null
#  agency_phone    :string           not null
#  agency_fare_url :string           not null
#  agency_email    :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  feed_version_id :integer          not null
#
# Indexes
#
#  index_gtfs_agencies_on_agency_id    (agency_id)
#  index_gtfs_agencies_on_agency_name  (agency_name)
#  index_gtfs_agencies_unique          (feed_version_id,agency_id) UNIQUE
#

FactoryGirl.define do
    factory :gtfs_agency do
        agency_id "test"
        agency_name "Test Agency"
        agency_url "http://example.com"
        agency_timezone "America/Los_Angeles"
        agency_lang "en"
        agency_phone "555-555-5555"
        agency_fare_url "http://example.com/fares"
        agency_email "transit@example.com"
        association :feed_version
    end

    factory :gtfs_agency_bart, parent: :gtfs_agency, class: GTFSAgency do
        agency_id "BART"
        agency_name "Bay Area Rapid Transit"
        agency_url "http://www.bart.gov"
        agency_timezone "America/Los_Angeles"
        agency_lang "en"
        agency_phone "510-555-5555"
        agency_fare_url "http://www.bart.gov/fares"
        agency_email "info@bart.gov"
    end
end  
