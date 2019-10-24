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
#  route_stop_pattern_id              :integer
#  origin_dist_traveled               :float
#  destination_dist_traveled          :float
#  feed_id                            :integer
#  feed_version_id                    :integer
#  frequency_type                     :string
#  frequency_headway_seconds          :integer
#
# Indexes
#
#  current_schedule_stop_pairs64_created_or_updated_in_changes_idx  (created_or_updated_in_changeset_id)
#  current_schedule_stop_pairs64_destination_id_idx                 (destination_id)
#  current_schedule_stop_pairs64_feed_id_id_idx                     (feed_id,id)
#  current_schedule_stop_pairs64_feed_version_id_id_idx             (feed_version_id,id)
#  current_schedule_stop_pairs64_frequency_type_idx                 (frequency_type)
#  current_schedule_stop_pairs64_operator_id_id_idx                 (operator_id,id)
#  current_schedule_stop_pairs64_origin_departure_time_idx          (origin_departure_time)
#  current_schedule_stop_pairs64_origin_id_idx                      (origin_id)
#  current_schedule_stop_pairs64_route_id_idx                       (route_id)
#  current_schedule_stop_pairs64_route_stop_pattern_id_idx          (route_stop_pattern_id)
#  current_schedule_stop_pairs64_service_end_date_idx               (service_end_date)
#  current_schedule_stop_pairs64_service_start_date_idx             (service_start_date)
#  current_schedule_stop_pairs64_trip_idx                           (trip)
#  current_schedule_stop_pairs64_updated_at_idx                     (updated_at)
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

  context 'route and operator set by route_onestop_id=' do
    it '#route_onestop_id= sets route' do
      ssp = create(:schedule_stop_pair)
      ssp.route_onestop_id = route.onestop_id
      expect(ssp.route).to eq(route)
    end

    it '#route_onestop_id= sets operator' do
      ssp = create(:schedule_stop_pair)
      ssp.route_onestop_id = route.onestop_id
      expect(ssp.operator).to be_truthy
      expect(ssp.operator).to eq(route.operator)
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
      # FIXME: build doesn't save before apply, so no schema validation.
      # Use create! instead, but need to update payload to use camelCase.
      changeset.change_payloads.build(payload: payload)
      changeset.apply!
      ssp = changeset.schedule_stop_pairs_created_or_updated.first
      expect(ssp.created_or_updated_in_changeset).to eq changeset
      expect(ssp.origin).to eq stop1
      expect(ssp.destination).to eq stop2
      expect(ssp.operator).to be_truthy
      expect(ssp.operator).to eq route.operator
      expect(stop1.trips_out).to match_array([ssp])
      expect(stop2.trips_in).to match_array([ssp])
      expect(stop1.stops_out).to match_array([stop2])
      expect(stop2.stops_in).to match_array([stop1])
    end
  end

  context 'scopes' do
    it 'where_imported_from_active_feed_version' do
      feed = create(:feed)
      feed_version1 = create(:feed_version, feed: feed)
      feed_version2 = create(:feed_version, feed: feed)
      feed.update!(active_feed_version: feed_version2)
      ssp1 = create(:schedule_stop_pair, feed_version: feed_version1, feed: feed)
      ssp2 = create(:schedule_stop_pair, feed_version: feed_version2, feed: feed)
      expect(ScheduleStopPair.all).to match_array([ssp1, ssp2])
      expect(ScheduleStopPair.where_imported_from_active_feed_version).to match_array([ssp2])
    end

    it 'where_import_level' do
      feed = create(:feed)
      feed_version1 = create(:feed_version, feed: feed, import_level: 1)
      feed_version2 = create(:feed_version, feed: feed, import_level: 2)
      feed.update!(active_feed_version: feed_version2)
      ssp1 = create(:schedule_stop_pair, feed_version: feed_version1, feed: feed)
      ssp2 = create(:schedule_stop_pair, feed_version: feed_version2, feed: feed)
      expect(ScheduleStopPair.where_import_level(1)).to match_array([ssp1])
      expect(ScheduleStopPair.where_import_level(2)).to match_array([ssp2])
    end

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
      expect_start = Date.new(2013, 01, 01)
      expect_end0 = Date.new(2014, 01, 01)
      expect_end1 = Date.new(2015, 01, 01)
      expect_end2 = Date.new(2016, 01, 01)
      create(:schedule_stop_pair, service_start_date: expect_start, service_end_date: expect_end0)
      create(:schedule_stop_pair, service_start_date: expect_start, service_end_date: expect_end1)
      expect(ScheduleStopPair.where_service_from_date(expect_start).count).to eq(2)
      expect(ScheduleStopPair.where_service_from_date(expect_end0).count).to eq(2)
      expect(ScheduleStopPair.where_service_from_date(expect_end1).count).to eq(1)
      expect(ScheduleStopPair.where_service_from_date(expect_end2).count).to eq(0)
    end

    it 'where service before date' do
      expect_none = Date.new(2010, 01, 01)
      expect_all = Date.new(2020, 01, 01)
      expect_start1 = Date.new(2013, 01, 01)
      expect_start2 = Date.new(2015, 01, 01)
      expect_end1 = Date.new(2016, 01, 01)
      expect_end2 = Date.new(2018, 01, 01)
      create(:schedule_stop_pair, service_start_date: expect_start1, service_end_date: expect_end1)
      create(:schedule_stop_pair, service_start_date: expect_start2, service_end_date: expect_end2)
      expect(ScheduleStopPair.where_service_before_date(expect_none).count).to eq(0)
      expect(ScheduleStopPair.where_service_before_date(expect_all).count).to eq(2)
      expect(ScheduleStopPair.where_service_before_date(expect_start1).count).to eq(1)
      expect(ScheduleStopPair.where_service_before_date(expect_start2).count).to eq(2)
    end

    it 'where service before and after dates' do
      # test where_service_before_date & where_service_from_date together
      expect_start1 = Date.new(2013, 01, 01)
      expect_start2 = Date.new(2015, 01, 01)
      expect_end1 = Date.new(2016, 01, 01)
      expect_end2 = Date.new(2018, 01, 01)
      create(:schedule_stop_pair, service_start_date: expect_start1, service_end_date: expect_end1)
      create(:schedule_stop_pair, service_start_date: expect_start2, service_end_date: expect_end2)
      tests = [
        ['2010-01-01', '2020-01-01', 2],
        ['2010-01-01', '2013-01-01', 1],
        ['2010-01-01', '2014-01-01', 1],
        ['2010-01-01', '2015-01-01', 2],
        ['2020-01-01', '2022-01-01', 0],
      ].each do |start_date, end_date, count|
        expect(
          ScheduleStopPair
            .where_service_from_date(start_date)
            .where_service_before_date(end_date)
            .count
        ).to eq(count)
      end
    end

    it 'where origin_departure_between' do
      create(:schedule_stop_pair, origin_departure_time: '09:00:00')
      create(:schedule_stop_pair, origin_departure_time: '09:05:00')
      create(:schedule_stop_pair, origin_departure_time: '09:10:00')
      expect(ScheduleStopPair.where_origin_departure_between('07:00:00', '08:00:00').count).to eq(0)
      expect(ScheduleStopPair.where_origin_departure_between('08:00:00', '09:00:00').count).to eq(1)
      expect(ScheduleStopPair.where_origin_departure_between('09:00:00', '09:00:00').count).to eq(1)
      expect(ScheduleStopPair.where_origin_departure_between('09:00:00', '09:01:00').count).to eq(1)
      expect(ScheduleStopPair.where_origin_departure_between('09:00:00', '09:05:00').count).to eq(2)
      expect(ScheduleStopPair.where_origin_departure_between('09:00:00', '09:10:00').count).to eq(3)
      expect(ScheduleStopPair.where_origin_departure_between('09:00:00', '10:00:00').count).to eq(3)
      expect(ScheduleStopPair.where_origin_departure_between('00:00:00', '30:00:00').count).to eq(3)
    end

    it 'where origin_departure_between parses widetimes' do
      create(:schedule_stop_pair, origin_departure_time: '09:00:00')
      expect(ScheduleStopPair.where_origin_departure_between('8', '10').count).to eq(1)
    end

    it 'where origin_departure_between allows open ended ranges' do
      create(:schedule_stop_pair, origin_departure_time: '09:00:00')
      expect(ScheduleStopPair.where_origin_departure_between('08:00:00', nil).count).to eq(1)
      expect(ScheduleStopPair.where_origin_departure_between(nil, '10:00:00').count).to eq(1)
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

    it 'service exceptions outside service_range will be filtered' do
      expect_start = Date.new(2015, 01, 01)
      expect_end = Date.new(2016, 01, 01)
      expect_unfiltered = Date.new(2015, 06, 01)
      expect_filtered = Date.new(2020, 01, 01)
      # Added
      ssp = build(
        :schedule_stop_pair,
        service_start_date: expect_start,
        service_end_date: expect_end,
        service_added_dates: [expect_unfiltered, expect_filtered],
        service_except_dates: [expect_unfiltered, expect_filtered]
      )
      expect(ssp.valid?).to be true
      expect(ssp.service_added_dates).to match_array([expect_unfiltered])
      expect(ssp.service_except_dates).to match_array([expect_unfiltered])
    end
  end

  context 'frequency' do
    it 'validates frequency_headway_seconds' do
      ssp = create(:schedule_stop_pair)
      ssp.frequency_headway_seconds = -100
      expect(ssp.valid?).to be false
      ssp.frequency_headway_seconds = 100
      expect(ssp.valid?).to be true
    end

    it 'frequency dependencies' do
      ssp = create(:schedule_stop_pair)
      expect(ssp.errors.size).to eq(0)
      # frequency_type
      ssp.frequency_type = :exact
      ssp.valid?
      expect(ssp.errors.size).to eq(3)
      # frequency_headway_seconds
      ssp.frequency_headway_seconds = 600
      ssp.valid?
      expect(ssp.errors.size).to eq(2)
      # frequency_start_time, frequency_end_time
      ssp.frequency_start_time = "01:00:00"
      ssp.frequency_end_time = "02:00:00"
      ssp.valid?
      expect(ssp.errors.size).to eq(0)
      expect(ssp.valid?).to be_truthy
    end

    # TODO: Not yet supported - need to update json-schema to 2.7.0.
    # it 'JSON Schema dependencies' do
    #   ssp = create(:schedule_stop_pair)
    #   # base
    #   errors = ChangePayload.payload_validation_errors({changes: [{action: "createUpdate", scheduleStopPair: ssp.as_change.except(:frequencyType).as_json}]})
    #   expect(errors.size).to eq(0)
    #   # error
    #   ssp.frequency_type = :exact
    #   errors = ChangePayload.payload_validation_errors({changes: [{action: "createUpdate", scheduleStopPair: ssp.as_change.as_json}]})
    #   expect(errors.size).to be > 0
    #   # fixed
    #   ssp.frequency_start_time = '08:00:00'
    #   ssp.frequency_end_time = '12:00:00'
    #   ssp.frequency_headway_seconds = 600
    #   errors = ChangePayload.payload_validation_errors({changes: [{action: "createUpdate", scheduleStopPair: ssp.as_change.as_json}]})
    #   expect(errors.size).to eq(0)
    # end
  end

  context 'ssp interpolation' do
    it 'raises unknown interpolation method' do
      expect { ScheduleStopPair.interpolate([], :unknown) }.to raise_error(ArgumentError)
    end

    it 'linear interpolation' do
      ssps = []
      ssps << build(
        :schedule_stop_pair,
        origin_arrival_time: '10:00:00',
        origin_departure_time: '10:10:00',
        destination_arrival_time: nil,
        destination_departure_time: nil
      )
      3.times.each do |i|
        ssps << build(
          :schedule_stop_pair,
          origin_arrival_time: nil,
          origin_departure_time: nil,
          destination_arrival_time: nil,
          destination_departure_time: nil
        )
      end
      ssps << build(
        :schedule_stop_pair,
        origin_arrival_time: nil,
        origin_departure_time: nil,
        destination_arrival_time: '10:40:00',
        destination_departure_time: '10:50:00'
      )
      ScheduleStopPair.interpolate(ssps, :linear)
      expect(ssps[0].destination_arrival_time).to eq('10:16:00')
      expect(ssps[1].origin_departure_time).to eq('10:16:00')
      expect(ssps[1].destination_arrival_time).to eq('10:22:00')
      expect(ssps[2].origin_departure_time).to eq('10:22:00')
      expect(ssps[2].destination_arrival_time).to eq('10:28:00')
      expect(ssps[3].origin_arrival_time).to eq('10:28:00')
      expect(ssps[3].destination_arrival_time).to eq('10:34:00')
      expect(ssps[4].origin_departure_time).to eq('10:34:00')
      # Check window
      expect(ssps[1].window_start).to eq(ssps[0].origin_departure_time)
      expect(ssps[1].window_end).to eq(ssps[4].destination_arrival_time)
      # Check interpolation method
      expect(ssps[0].origin_timepoint_source).to eq('gtfs_exact')
      expect(ssps[0].destination_timepoint_source).to eq('transitland_interpolated_linear')
      expect(ssps[4].destination_timepoint_source).to eq('gtfs_exact')
    end
  end
end
