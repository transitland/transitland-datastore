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
#  calendar                           :hstore
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#
# Indexes
#
#  c_ssp_cu_in_changeset                                     (created_or_updated_in_changeset_id)
#  c_ssp_origin_id_and_destination_id_and_route_id_and_trip  (origin_id,destination_id,route_id,trip) UNIQUE
#  index_current_schedule_stop_pairs_on_destination_id       (destination_id)
#  index_current_schedule_stop_pairs_on_origin_id            (origin_id)
#  index_current_schedule_stop_pairs_on_route_id             (route_id)
#  index_current_schedule_stop_pairs_on_trip                 (trip)
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
    # tags ""
    # calendar ""
  end

end
