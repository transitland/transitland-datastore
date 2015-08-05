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

RSpec.describe ScheduleStopPair, type: :model do
  let(:stop1) {create(:stop)}
  let(:stop2) {create(:stop)}
  let(:route) {create(:route)}
  
  it 'can be created' do
    ssp = create(:schedule_stop_pair)
    expect(ScheduleStopPair.exists?(ssp.id)).to be true
  end

  it 'has two stops' do
    ssp = create(:schedule_stop_pair)
    expect(Stop.exists?(ssp.origin_id)).to be true
    expect(Stop.exists?(ssp.destination_id)).to be true
  end

  it 'has a changeset' do
    ssp = create(:schedule_stop_pair)
    expect(Changeset.exists?(ssp.created_or_updated_in_changeset_id))
  end

  it 'creates a stop-ssp association' do
    ssp = create(:schedule_stop_pair)
    origin = ssp.origin
    destination = ssp.destination
    expect(origin.trips_out).to match_array([ssp])
    expect(origin.trips_in).to be_empty
    expect(destination.trips_in).to match_array([ssp])
    expect(destination.trips_out).to be_empty
  end

  it 'creates a stop-stop through association' do
    ssp = create(:schedule_stop_pair)
    origin = ssp.origin
    destination = ssp.destination
    expect(origin.stops_out).to match_array([destination])
    expect(origin.stops_in).to be_empty
    expect(destination.stops_in).to match_array([origin])
    expect(destination.stops_out).to be_empty
  end
  
  it 'allows many stop-stop through associations' do
    ssp1 = create(:schedule_stop_pair, origin: stop1, destination: stop2)
    ssp2 = create(:schedule_stop_pair, origin: stop1, destination: stop2)
    expect(stop1.trips_out).to match_array([ssp1, ssp2])
    expect(stop2.trips_in).to match_array([ssp1, ssp2])
  end
  
  it 'can be created through a changeset' do
    ssp_attr = attributes_for(
      :schedule_stop_pair,
      origin_onestop_id: stop1.onestop_id,
      destination_onestop_id: stop2.onestop_id,
      route_onestop_id: route.onestop_id
    )
    payload = {
      changes: [
        {
          action: "createUpdate",
          schedule_stop_pair: ssp_attr
        }
      ]
    }    
    changeset = create(:changeset)
    changeset.append(payload)
    changeset.apply!
    ssp = changeset.schedule_stop_pairs_created_or_updated.first
    expect(ssp.created_or_updated_in_changeset).to eq changeset
    expect(ssp.origin).to eq stop1
    expect(ssp.destination).to eq stop2
    expect(stop1.trips_out).to match_array([ssp])
    expect(stop2.trips_in).to match_array([ssp])
    expect(stop1.stops_out).to match_array([stop2])
    expect(stop2.stops_in).to match_array([stop1])
  end

end
