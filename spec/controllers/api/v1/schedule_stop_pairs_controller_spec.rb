describe Api::V1::ScheduleStopPairsController do

  before(:each) do
    # Create feeds
    @feed = create(:feed)
    @feed_version_inactive = create(:feed_version, feed: @feed, import_level: 2)
    @feed_version_active = create(:feed_version, feed: @feed, import_level: 3)
    @feed.update(active_feed_version: @feed_version_active)
    # 1 inactive, 2 active
    @ssps = []
    @ssps << create(:schedule_stop_pair, feed: @feed_version_inactive.feed, feed_version: @feed_version_inactive)
    @ssps << create(:schedule_stop_pair, feed: @feed_version_active.feed, feed_version: @feed_version_active)
    @ssps << create(:schedule_stop_pair, feed: @feed_version_active.feed, feed_version: @feed_version_active)
  end

  describe 'GET index' do
    context 'default' do
      it 'returns all SSPs' do
        get :index
        expect_json_sizes(schedule_stop_pairs: 3)
      end
    end

    context 'feed_onestop_id' do
      it 'filters by feed_onestop_id' do
        get :index, feed_onestop_id: @feed.onestop_id
        expect_json_sizes(schedule_stop_pairs: 3)
      end
    end

    context 'feed_version_sha1' do
      it 'filters by feed_version_sha1' do
        get :index, feed_version_sha1: @feed_version_active.sha1
        expect_json_sizes(schedule_stop_pairs: 2)
      end
    end

    context 'active' do
      it 'explicitly sets where_imported_from_active_feed_version' do
        get :index, active: 'true', feed_version_sha1: @feed_version_inactive.sha1
        expect_json_sizes(schedule_stop_pairs: 0)
      end
    end

    context 'import_level' do
      it 'filters by import_level' do
        get :index, import_level: 3
        expect_json_sizes(schedule_stop_pairs: 2)
      end
    end

    context 'date=today, time=now' do
      before(:each) {
        @origin = @ssps[0].origin
        @origin.update!(timezone: 'America/Los_Angeles')
        @ssps[0].update(
          origin: @origin,
          origin_departure_time: '10:00:00',
          service_start_date: '1999-01-01',
          service_end_date: '1999-01-01',
          service_days_of_week: [false, false, false, false, true, false, false]
        )
        @ssps[1].update(
          origin: @origin,
          origin_departure_time: '12:00:00',
          service_start_date: '1999-01-01',
          service_end_date: '1999-01-01',
          service_days_of_week: [false, false, false, false, true, false, false]
        )
        @ssps[2].update(
          origin: @origin,
          origin_departure_time: '14:00:00',
          service_start_date: '1999-02-01',
          service_end_date: '1999-02-01',
          service_days_of_week: [false, false, false, false, true, false, false]
        )
        @now = DateTime.parse('1999-01-01T18:00:00+00:00')
      }

      it 'accepts date=today' do
        Timecop.freeze(@now) do
          get :index, origin_onestop_id: @origin.onestop_id, date: 'today'
          expect_json_sizes(schedule_stop_pairs: 2)
        end
      end

      it 'accepts origin_departure_between=now' do
        Timecop.freeze(@now) do
          # now is 10am America/Los_Angeles
          get :index, origin_onestop_id: @origin.onestop_id, origin_departure_between: '11:00:00'
          expect_json_sizes(schedule_stop_pairs: 2)
          get :index, origin_onestop_id: @origin.onestop_id, origin_departure_between: 'now-600'
          expect_json_sizes(schedule_stop_pairs: 3)
          get :index, origin_onestop_id: @origin.onestop_id, origin_departure_between: 'now+600'
          expect_json_sizes(schedule_stop_pairs: 2)
          get :index, origin_onestop_id: @origin.onestop_id, origin_departure_between: '00:00:00,now+600'
          expect_json_sizes(schedule_stop_pairs: 1)
          get :index, origin_onestop_id: @origin.onestop_id, origin_departure_between: 'now-600,now+600'
          expect_json_sizes(schedule_stop_pairs: 1)
        end
      end
    end

    context 'service_from_date' do
    end

    context 'service_before_date' do
    end

    context 'origin_onestop_id' do
    end

    context 'destination_onestop_id' do
    end

    context 'origin_departure_between' do
    end

    context 'trip' do
    end

    context 'route_onestop_id' do
    end

    context 'route_stop_pattern_onestop_id' do
    end

    context 'operator_onestop_id' do
    end

    context 'bbox' do
    end

    context 'updated_since' do
    end

    context 'included' do
    end
  end
end
