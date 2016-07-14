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

    context 'where_active' do
      it 'explicitly sets where_active' do
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

    context 'date' do
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
