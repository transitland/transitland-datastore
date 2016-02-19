describe Api::V1::ScheduleStopPairsController do

  before(:each) do
    @feed = create(:feed)
    @feed_version1 = create(:feed_version, feed: @feed)
    @ssp1 = create(:schedule_stop_pair, feed: @feed_version1.feed, feed_version: @feed_version1)
    @feed.update(active_feed_version: @feed_version1)
    @feed_version2 = create(:feed_version, feed: @feed)
    @ssp2 = create(:schedule_stop_pair, feed: @feed_version2.feed, feed_version: @feed_version2)
  end

  describe 'GET index' do
    context 'default' do
      it 'where_active default scope' do
        get :index
        expect(JSON.parse(response.body)["schedule_stop_pairs"].size).to eq(1)
      end
    end

    context 'feed_onestop_id' do
      it 'filters by feed_onestop_id' do

      end
    end

    context 'feed_version_sha1' do
      it 'filters by feed_version_sha1' do

      end

      it 'overrides default where_active scope' do

      end
    end
  end


end
