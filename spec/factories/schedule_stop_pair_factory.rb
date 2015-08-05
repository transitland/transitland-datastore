# == Schema Information
#
# Table name: current_schedule_stop_pairs
#
#  id                                 :integer          not null, primary key
#  origin_id                          :integer
#  destination_id                     :integer
#  route_id                           :integer
#  trip                               :string
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  trip_headsign                      :string
#  origin_arrival_time                :string
#  origin_departure_time              :string
#  destination_arrival_time           :string
#  destination_departure_time         :string
#  frequency_start_time               :string
#  frequency_end_time                 :string
#  frequency_headway_seconds          :string
#  tags                               :hstore
#  service_start_date                 :string
#  service_end_date                   :string
#  service_sunday                     :boolean
#  service_monday                     :boolean
#  service_tuesday                    :boolean
#  service_wednesday                  :boolean
#  service_thursday                   :boolean
#  service_friday                     :boolean
#  service_saturday                   :boolean
#  service_added                      :string           default([]), is an Array
#  service_except                     :string           default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#
# Indexes
#
#  c_ssp_cu_in_changeset     (created_or_updated_in_changeset_id)
#  c_ssp_destination         (destination_id)
#  c_ssp_origin              (origin_id)
#  c_ssp_route               (route_id)
#  c_ssp_service_end_date    (service_end_date)
#  c_ssp_service_start_date  (service_start_date)
#  c_ssp_trip                (trip)
#

FactoryGirl.define do
  factory :schedule_stop_pair do
    association :origin, factory: :stop
    association :destination, factory: :stop
    association :route, factory: :route
    association :created_or_updated_in_changeset, factory: :changeset
    version 1
    trip "1234"
    origin_arrival_time "10:00:00"
    origin_departure_time "10:00:10"
    destination_arrival_time "10:10:00"
    destination_departure_time "10:10:10"
    service_start_date "20000101"
    service_end_date "21000101"
    service_added ["20150101", "20150102"]
    service_except ["20150103", "20150104"]
    service_sunday false
    service_monday true
    service_tuesday true
    service_wednesday true
    service_thursday true
    service_friday true
    service_saturday false
    # tags ""
  end

end
