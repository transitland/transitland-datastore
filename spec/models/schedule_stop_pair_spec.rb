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
#  wheelchair_accessible              :integer
#  bikes_allowed                      :integer
#  pickup_type                        :integer
#  drop_off_type                      :integer
#  timepoint                          :integer
#  shape_dist_traveled                :float
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
  
  context 'has stops' do
    it 'has two stops' do
      ssp = create(:schedule_stop_pair)
      expect(Stop.exists?(ssp.origin_id)).to be true
      expect(Stop.exists?(ssp.destination_id)).to be true
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
  end
  
  context 'changeset' do
    it 'has a changeset' do
      ssp = create(:schedule_stop_pair)
      expect(Changeset.exists?(ssp.created_or_updated_in_changeset_id))
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

  context 'scopes' do
    it 'where service on date' do
      expect_start = Date.new(2015, 01, 01)
      expect_end = Date.new(2016, 01, 01)
      expect_dow = [true, true, true, true, true, false, false]
      expect_service = Date.new(2015, 8, 7) # a Friday
      expect_none = Date.new(2015, 8, 8) # a Saturday
      create(:schedule_stop_pair, service_start_date: expect_start, service_end_date: expect_end, service_days_of_week: expect_dow)
      expect(ScheduleStopPair.where_service_on_date(expect_service).count).to eq(1)
      expect(ScheduleStopPair.where_service_on_date(expect_none).count).to eq(0)
    end
    
    it 'where service from date' do
      expect_start = Date.new(2016, 01, 01)
      expect_end0 = Date.new(2014, 01, 01)
      expect_end1 = Date.new(2015, 01, 01)
      expect_end2 = Date.new(2015, 06, 01)
      expect_end3 = Date.new(2016, 01, 01)
      create(:schedule_stop_pair, service_start_date: expect_start, service_end_date: expect_end1)
      create(:schedule_stop_pair, service_start_date: expect_start, service_end_date: expect_end2)
      expect(ScheduleStopPair.where_service_from_date(expect_end0).count).to eq(2)
      expect(ScheduleStopPair.where_service_from_date(expect_end1).count).to eq(2)
      expect(ScheduleStopPair.where_service_from_date(expect_end2).count).to eq(1)
      expect(ScheduleStopPair.where_service_from_date(expect_end3).count).to eq(0)
    end
    
  end

  context 'service dates' do
    it 'must have service_start_date' do
      ssp = build(:schedule_stop_pair, service_start_date: nil, service_added_dates: [], service_except_dates: [])
      expect(ssp.valid?).to be false
    end

    it 'must have service_end_date' do
      ssp = build(:schedule_stop_pair, service_end_date: nil, service_added_dates: [], service_except_dates: [])
      ssp.service_end_date = nil
      expect(ssp.valid?).to be false      
    end
    
    it 'may set service range from service_added_dates and service_except_dates' do
      expect_start = Date.new(2015, 01, 01)
      expect_end = Date.new(2016, 01, 01)
      ssp = build(:schedule_stop_pair, service_start_date: nil, service_end_date: nil, service_added_dates: [expect_start], service_except_dates: [expect_end])
      expect(ssp.valid?).to be true
      expect(ssp.service_start_date).to eq(expect_start)
      expect(ssp.service_end_date).to eq(expect_end)
    end

    it 'service on date' do
      expect_start = Date.new(2015, 01, 01)
      expect_end = Date.new(2016, 01, 01)
      expect_service = Date.new(2015, 8, 7) # a Friday
      expect_none = Date.new(2015, 8, 8) # a Saturday
      expect_dow = [true, true, true, true, true, false, false]
      ssp = create(:schedule_stop_pair, service_start_date: expect_start, service_end_date: expect_end, service_days_of_week: expect_dow)
      expect(ssp.service_on_date?(expect_service)).to be true
      expect(ssp.service_on_date?(expect_none)).to be false
    end

    it 'service exceptions must be in service range' do
      expect_start = Date.new(2015, 01, 01)
      expect_end = Date.new(2016, 01, 01)
      expect_fail = Date.new(2020, 01, 01)
      ssp = build(:schedule_stop_pair, service_start_date: expect_start, service_end_date: expect_end)
      expect(ssp.valid?).to be true    
      ssp.service_added_dates = [expect_fail]
      ssp.service_except_dates = []
      expect(ssp.valid?).to be false
      ssp.service_added_dates = []
      ssp.service_except_dates = [expect_fail]
      expect(ssp.valid?).to be false
    end
  end  
end
