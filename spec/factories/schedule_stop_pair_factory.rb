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
#  service_start_date                 :date
#  service_end_date                   :date
#  service_added_dates                :date             default([]), is an Array
#  service_except_dates               :date             default([]), is an Array
#  service_days_of_week               :boolean          default([]), is an Array
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  block_id                           :string
#  trip_short_name                    :string
#  shape_dist_traveled                :float
#  origin_timezone                    :string
#  destination_timezone               :string
#  window_start                       :string
#  window_end                         :string
#  origin_timepoint_source            :string
#  destination_timepoint_source       :string
#  operator_id                        :integer
#  wheelchair_accessible              :boolean
#  bikes_allowed                      :boolean
#  pickup_type                        :string
#  drop_off_type                      :string
#  active                             :boolean
#  route_stop_pattern_id              :integer
#  route_stop_pattern_type            :string
#  origin_dist_traveled               :float
#  destination_dist_traveled          :float
#
# Indexes
#
#  c_ssp_cu_in_changeset                                       (created_or_updated_in_changeset_id)
#  c_ssp_destination                                           (destination_id)
#  c_ssp_origin                                                (origin_id)
#  c_ssp_route                                                 (route_id)
#  c_ssp_service_end_date                                      (service_end_date)
#  c_ssp_service_start_date                                    (service_start_date)
#  c_ssp_trip                                                  (trip)
#  index_current_schedule_stop_pairs_on_active                 (active)
#  index_current_schedule_stop_pairs_on_operator_id            (operator_id)
#  index_current_schedule_stop_pairs_on_origin_departure_time  (origin_departure_time)
#  index_current_schedule_stop_pairs_on_updated_at             (updated_at)
#

FactoryGirl.define do
  factory :schedule_stop_pair do
    association :origin, factory: :stop
    association :destination, factory: :stop
    association :route, factory: :route
    association :operator
    association :created_or_updated_in_changeset, factory: :changeset
    version 1
    trip "1234"
    origin_timezone "America/Los_Angeles"
    destination_timezone "America/Los_Angeles"
    origin_arrival_time "10:00:00"
    origin_departure_time "10:00:10"
    destination_arrival_time "10:10:00"
    destination_departure_time "10:10:10"
    service_start_date "2000-01-01"
    service_end_date "2100-01-01"
    service_added_dates []
    service_except_dates []
    service_days_of_week [true, true, true, true, true, false, false] # M - F
  end

end
